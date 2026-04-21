# libtex3ds — API Reference (English)

> **Language / Langue:** [English](api-en.md) | [Français](api-fr.md)  
> Back to [README](../README.md)

---

## Table of Contents

- [Types](#types)
  - [Quantum](#quantum)
  - [RGBA](#rgba)
  - [Image](#image)
- [Enumerations](#enumerations)
  - [ProcessFormat](#processformat)
  - [CompressionFormat](#compressionformat)
  - [etc1\_quality](#etc1_quality)
- [Params](#params)
- [Process()](#process)
- [Examples](#examples)
- [Constraints & Limitations](#constraints--limitations)
- [Output File Format](#output-file-format)

---

## Types

### `Quantum`

```cpp
using Tex3DS::Quantum = uint8_t;
static constexpr uint8_t Tex3DS::QuantumRange = 255;
```

Represents a single color channel value in the range `[0, 255]`.

---

### `RGBA`

```cpp
struct Tex3DS::RGBA {
    Quantum b, g, r, a;
};
```

One pixel. Despite the name, fields are stored in **B, G, R, A** memory order to match the 3DS little-endian convention. Always set channels by name to avoid mistakes:

```cpp
Tex3DS::RGBA px;
px.r = 255; px.g = 128; px.b = 0; px.a = 255;
```

---

### `Image`

```cpp
struct Tex3DS::Image {
    size_t stride = 0;          // row width in pixels (normally == w)
    size_t w      = 0;          // image width in pixels
    size_t h      = 0;          // image height in pixels
    std::vector<RGBA> pixels;   // row-major pixel data, size = stride * h

    Image() = default;
    Image(size_t w, size_t h);  // allocates w*h zero-initialized pixels
};
```

Fill pixels using `img.pixels[y * img.stride + x]`.

---

## Enumerations

### `ProcessFormat`

The target pixel encoding written into the `.t3x` file.

| Enumerator | Bits/px | Description |
|---|---|---|
| `RGBA8888` | 32 | Full color + full alpha. Output byte order: A, B, G, R. |
| `RGB888` | 24 | Full color, no alpha (forced to 255). Output byte order: B, G, R. |
| `RGBA5551` | 16 | 5-bit R, G, B + 1-bit alpha. |
| `RGB565` | 16 | 5-bit R, 6-bit G, 5-bit B. No alpha. |
| `RGBA4444` | 16 | 4 bits per channel. |
| `LA88` | 16 | Luminance (8-bit) + alpha (8-bit). Output byte order: alpha, luminance. |
| `HILO88` | 16 | Red channel → HI byte, green channel → LO byte. Blue and alpha ignored. |
| `L8` | 8 | Luminance only. Alpha ignored. |
| `A8` | 8 | Alpha only. RGB ignored. |
| `LA44` | 8 | 4-bit luminance + 4-bit alpha. |
| `L4` | 4 | 4-bit luminance. Two pixels packed per byte (first pixel in low nibble). |
| `A4` | 4 | 4-bit alpha. Two pixels packed per byte (first pixel in low nibble). |
| `ETC1` | 4 | ETC1 block compression. No alpha. |
| `ETC1A4` | 8 | ETC1 block compression + 4-bit alpha block. |
| `AUTO_L8` | — | Alias for `LA88` in library mode. |
| `AUTO_L4` | — | Alias for `LA44` in library mode. |
| `AUTO_ETC1` | — | Alias for `ETC1A4` in library mode. |

Luminance is computed with ITU-R BT.709 coefficients (R: 0.2127, G: 0.7152, B: 0.0722) and proper sRGB gamma correction.

> **Choosing a format:**
> - Use `RGB565` or `RGB888` for fully opaque images.
> - Use `RGBA4444` or `RGBA5551` for images with simple transparency.
> - Use `ETC1` / `ETC1A4` for maximum compression at the cost of encoding time.
> - Use `L8` / `LA88` for grayscale or icon assets.

---

### `CompressionFormat`

Secondary compression applied to the encoded pixel block before writing to disk.

| Enumerator | Description |
|---|---|
| `COMPRESSION_NONE` | No compression. Data is wrapped in a 4-byte GBA-style header. |
| `COMPRESSION_LZ10` | LZSS / LZ10. Max match: 18 bytes, max displacement: 4096 bytes. |
| `COMPRESSION_LZ11` | LZ11. Max match: 65 808 bytes, max displacement: 4096 bytes. |
| `COMPRESSION_RLE` | Run-length encoding. Min run: 3 bytes, max run: 130 bytes. |
| `COMPRESSION_HUFF` | 8-bit Huffman coding. |
| `COMPRESSION_AUTO` | Tries all five methods, prints the winner to stdout, and picks the smallest output. |

> `COMPRESSION_LZ11` is a good default for most textures. Use `COMPRESSION_AUTO` when output size matters more than build time.

---

### `rg_etc1::etc1_quality`

```cpp
enum rg_etc1::etc1_quality {
    cLowQuality,
    cMediumQuality,
    cHighQuality,
};
```

Controls the ETC1 encoder quality/speed trade-off. Only relevant when `process_format` is `ETC1`, `ETC1A4`, or `AUTO_ETC1`.

| Value | Speed | Quality |
|---|---|---|
| `cLowQuality` | Fast | Lower |
| `cMediumQuality` | Moderate | Good (default) |
| `cHighQuality` | Slow | Best |

---

## `Params`

```cpp
struct Tex3DS::Params {
    std::string              output_path        = "";
    ProcessFormat            process_format     = RGBA8888;
    rg_etc1::etc1_quality    etc1_quality       = rg_etc1::cMediumQuality;
    CompressionFormat        compression_format = COMPRESSION_AUTO;
    Image                    input_img;
};
```

| Field | Type | Default | Description |
|---|---|---|---|
| `output_path` | `std::string` | `""` | Path to the output `.t3x` file. If empty, encoding is done in memory but nothing is written to disk. |
| `process_format` | `ProcessFormat` | `RGBA8888` | Target pixel encoding format. |
| `etc1_quality` | `etc1_quality` | `cMediumQuality` | ETC1 encoder quality. Ignored for non-ETC1 formats. |
| `compression_format` | `CompressionFormat` | `COMPRESSION_AUTO` | Compression applied to the pixel data. |
| `input_img` | `Image` | — | The source image. **Must be set before calling `Process`.** |

---

## `Process()`

```cpp
bool Tex3DS::Process(const Tex3DS::Params& params);
```

Converts the source image and writes a `.t3x` file.

**Returns** `true` on success, `false` on any error (error details are printed to `stderr`).

**Internal steps:**

1. Validates that `w` and `h` are both ≤ 1024.
2. Pads the canvas to the next power-of-two in each dimension (minimum 8×8). The extra area is zero-initialized.
3. Computes normalized UV sub-image coordinates for the original visible region within the padded canvas.
4. Applies Morton/Z-order (swizzle) tile layout to the pixel array (skipped for ETC1/ETC1A4, which tile internally).
5. Encodes pixels tile by tile in 8×8 blocks using the selected `ProcessFormat`.
6. Applies the selected `CompressionFormat` to the encoded data.
7. If `output_path` is non-empty: writes the binary `.t3x` file (header + compressed data).

**Example:**

```cpp
Tex3DS::Params params;
params.input_img          = std::move(myImage);
params.output_path        = "textures/icon.t3x";
params.process_format     = Tex3DS::RGBA4444;
params.compression_format = Tex3DS::COMPRESSION_LZ11;

if (!Tex3DS::Process(params)) {
    // check stderr for the error message
}
```

---

## Examples

### 0. Simple PNG conversion (stb_image)

libtex3ds does not load images itself — you need to decode the PNG first.  
The easiest way is [`stb_image.h`](https://github.com/nothings/stb/blob/master/stb_image.h) (single-file, no dependencies — just drop it in your project).

**Opaque PNG → RGB565:**

```cpp
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#include "libtex3ds.h"

bool pngToT3x(const char* png_path, const char* out_path) {
    int w, h, channels;
    uint8_t* data = stbi_load(png_path, &w, &h, &channels, 4); // force RGBA
    if (!data) return false;

    Tex3DS::Image img(w, h);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            const uint8_t* src = data + (y * w + x) * 4;
            Tex3DS::RGBA& px   = img.pixels[y * img.stride + x];
            px.r = src[0]; px.g = src[1]; px.b = src[2]; px.a = src[3];
        }
    }
    stbi_image_free(data);

    Tex3DS::Params params;
    params.input_img      = std::move(img);
    params.output_path    = out_path;
    params.process_format = Tex3DS::RGB565;

    return Tex3DS::Process(params);
}
```

**PNG with transparency → RGBA4444:**

```cpp
bool pngTransparentToT3x(const char* png_path, const char* out_path) {
    int w, h, channels;
    uint8_t* data = stbi_load(png_path, &w, &h, &channels, 4);
    if (!data) return false;

    Tex3DS::Image img(w, h);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            const uint8_t* src = data + (y * w + x) * 4;
            Tex3DS::RGBA& px   = img.pixels[y * img.stride + x];
            px.r = src[0]; px.g = src[1]; px.b = src[2]; px.a = src[3];
        }
    }
    stbi_image_free(data);

    Tex3DS::Params params;
    params.input_img      = std::move(img);
    params.output_path    = out_path;
    params.process_format = Tex3DS::RGBA4444; // preserves alpha
    // use RGBA8888 if you need full alpha precision

    return Tex3DS::Process(params);
}
```

> `stbi_load` always outputs pixels in R, G, B, A memory order with the 4-channel forced read — map them directly to `px.r/g/b/a`.

---

### 1. Opaque background texture (RGB565)

Best format for fully opaque images — 16 bpp, no alpha, good quality.

```cpp
#include "libtex3ds.h"

// Assume raw_pixels is a flat uint8_t array of RGBA bytes (4 bytes per pixel)
// with dimensions 512x256, already loaded from a PNG decoder or similar.
bool convertBackground(const uint8_t* raw_pixels, size_t w, size_t h) {
    Tex3DS::Image img(w, h);

    for (size_t y = 0; y < h; ++y) {
        for (size_t x = 0; x < w; ++x) {
            const uint8_t* src = raw_pixels + (y * w + x) * 4;
            Tex3DS::RGBA& px   = img.pixels[y * img.stride + x];
            px.r = src[0];
            px.g = src[1];
            px.b = src[2];
            px.a = src[3];
        }
    }

    Tex3DS::Params params;
    params.input_img          = std::move(img);
    params.output_path        = "bg.t3x";
    params.process_format     = Tex3DS::RGB565;
    params.compression_format = Tex3DS::COMPRESSION_LZ11;

    return Tex3DS::Process(params);
}
```

---

### 2. Sprite sheet with transparency (RGBA4444)

4 bits per channel — cuts memory in half vs RGBA8888, good for UI sprites with soft edges.

```cpp
bool convertSpriteSheet(const uint8_t* raw_pixels, size_t w, size_t h) {
    Tex3DS::Image img(w, h);

    for (size_t y = 0; y < h; ++y) {
        for (size_t x = 0; x < w; ++x) {
            const uint8_t* src = raw_pixels + (y * w + x) * 4;
            Tex3DS::RGBA& px   = img.pixels[y * img.stride + x];
            px.r = src[0];
            px.g = src[1];
            px.b = src[2];
            px.a = src[3];
        }
    }

    Tex3DS::Params params;
    params.input_img          = std::move(img);
    params.output_path        = "sprites.t3x";
    params.process_format     = Tex3DS::RGBA4444;
    params.compression_format = Tex3DS::COMPRESSION_LZ11;

    return Tex3DS::Process(params);
}
```

---

### 3. High-quality compressed texture (ETC1A4)

ETC1A4 gives the best compression ratio for opaque or semi-transparent textures. Use `cHighQuality` for final builds, `cLowQuality` for fast iteration.

```cpp
bool convertCompressed(const uint8_t* raw_pixels, size_t w, size_t h, bool finalBuild) {
    Tex3DS::Image img(w, h);

    for (size_t y = 0; y < h; ++y) {
        for (size_t x = 0; x < w; ++x) {
            const uint8_t* src = raw_pixels + (y * w + x) * 4;
            Tex3DS::RGBA& px   = img.pixels[y * img.stride + x];
            px.r = src[0]; px.g = src[1]; px.b = src[2]; px.a = src[3];
        }
    }

    Tex3DS::Params params;
    params.input_img          = std::move(img);
    params.output_path        = "texture.t3x";
    params.process_format     = Tex3DS::ETC1A4;
    params.etc1_quality       = finalBuild ? rg_etc1::cHighQuality
                                           : rg_etc1::cLowQuality;
    params.compression_format = Tex3DS::COMPRESSION_LZ11;

    return Tex3DS::Process(params);
}
```

---

### 4. Grayscale font atlas (L8)

Single-channel luminance — ideal for monochrome font bitmaps or shadow maps.

```cpp
bool convertFontAtlas(const uint8_t* gray_pixels, size_t w, size_t h) {
    // gray_pixels is 1 byte per pixel (grayscale)
    Tex3DS::Image img(w, h);

    for (size_t y = 0; y < h; ++y) {
        for (size_t x = 0; x < w; ++x) {
            Tex3DS::RGBA& px = img.pixels[y * img.stride + x];
            px.r = gray_pixels[y * w + x];
            px.g = px.r;
            px.b = px.r;
            px.a = 255;
        }
    }

    Tex3DS::Params params;
    params.input_img          = std::move(img);
    params.output_path        = "font.t3x";
    params.process_format     = Tex3DS::L8;
    params.compression_format = Tex3DS::COMPRESSION_RLE; // fonts compress well with RLE

    return Tex3DS::Process(params);
}
```

---

### 5. Encode in memory without writing a file

Set `output_path` to `""` to run the full encoding pipeline without touching the disk.  
Useful for validating parameters or profiling.

```cpp
bool validateEncoding(Tex3DS::Image img) {
    Tex3DS::Params params;
    params.input_img          = std::move(img);
    params.output_path        = "";              // no file written
    params.process_format     = Tex3DS::RGBA8888;
    params.compression_format = Tex3DS::COMPRESSION_NONE;

    return Tex3DS::Process(params);
}
```

---

### 6. Batch convert a list of files

```cpp
#include "libtex3ds.h"
#include <vector>
#include <string>

struct TextureJob {
    Tex3DS::Image       image;
    std::string         output_path;
    Tex3DS::ProcessFormat format;
};

bool batchConvert(std::vector<TextureJob> jobs) {
    for (auto& job : jobs) {
        Tex3DS::Params params;
        params.input_img          = std::move(job.image);
        params.output_path        = job.output_path;
        params.process_format     = job.format;
        params.compression_format = Tex3DS::COMPRESSION_LZ11;

        if (!Tex3DS::Process(params)) {
            // Process() already printed the error to stderr
            return false;
        }
    }
    return true;
}
```

---

## Constraints & Limitations

| Constraint | Detail |
|---|---|
| Maximum input size | 1024 × 1024 pixels |
| Minimum output size | 8 × 8 pixels (smaller inputs are padded) |
| Power-of-two padding | Dimensions are always padded to the next power-of-two internally |
| RGBA field order | Struct fields are in **B, G, R, A** memory order — always use named fields |
| ETC1 thread safety | `pack_etc1_block_init()` is called automatically by `Process` but is **not thread-safe**. Do not call `Process` with an ETC1 format concurrently from multiple threads. |
| No mipmap generation | The mipmap count is hardcoded to 0 |
| No image loading | The caller must supply pre-decoded RGBA pixel data |
| `AUTO_L*` / `AUTO_ETC1` | In library mode these behave identically to `LA88`, `LA44`, and `ETC1A4` (CLI auto-selection logic is not available) |
| `COMPRESSION_AUTO` | Prints the chosen compression method to stdout as a side effect |

---

## Output File Format

When `output_path` is set, `Process` writes a binary `.t3x` file with the following layout.

### Header

| Offset | Size | Field |
|---|---|---|
| 0 | 2 bytes | `uint16_t` — number of sub-images (always `1`) |
| 2 | 1 byte | Texture parameters: bits `[2:0]` = `log2(padded_w) − 3`, bits `[5:3]` = `log2(padded_h) − 3` |
| 3 | 1 byte | `ProcessFormat` enum value (`0x00`–`0x0D`) |
| 4 | 1 byte | Mipmap count (always `0`) |

### Per Sub-Image Record (appears once)

| Size | Field |
|---|---|
| 2 bytes | Pixel width of the original (unpadded) image |
| 2 bytes | Pixel height of the original (unpadded) image |
| 2 bytes | Left U coordinate × 1024 (fixed-point) |
| 2 bytes | Top V coordinate × 1024 (fixed-point) |
| 2 bytes | Right U coordinate × 1024 (fixed-point) |
| 2 bytes | Bottom V coordinate × 1024 (fixed-point) |

### Data Block

GBA-style compression header followed by compressed pixel data, padded to a 4-byte boundary.

**Compression header** (4 bytes normally, 8 bytes if uncompressed size ≥ 16 MB):

| Byte(s) | Content |
|---|---|
| 0 | Compression type: `0x00` none, `0x10` LZ10, `0x11` LZ11, `0x28` Huffman, `0x30` RLE |
| 1–3 | Uncompressed data size (little-endian 24-bit integer) |
