# libtex3ds

> **Navigate / Navigation:**  
> [🇬🇧 English](#english) | [🇫🇷 Français](#français)

---

<a id="english"></a>

## 🇬🇧 English

C++11 static library for converting RGBA pixel data into the Nintendo 3DS native texture format (`.t3x`).

It implements a library-form subset of the [`tex3ds`](https://github.com/devkitPro/tex3ds) command-line tool (originally by Michael Theall / mtheall; this fork by ds-sloth, 2024).

### Requirements

- CMake ≥ 3.2
- A C++11-capable compiler (GCC, Clang, MSVC)
- No external dependencies — the library is fully self-contained

### Build

```sh
# Using the provided script
./build.sh

# Or manually
mkdir -p build
cmake -S . -B build
make -C build
```

The static archive `libtex3ds.a` is produced in `build/` (and copied to the repo root by `build.sh`).

#### Install

```sh
cmake --install build
```

Installs `libtex3ds.a` to `lib/` and `public/libtex3ds.h` to `include/` using standard `GNUInstallDirs` paths.

### Quick Start

```cpp
#include "libtex3ds.h"

int main() {
    // 1. Create an image and fill pixels
    Tex3DS::Image img(320, 240);
    for (size_t y = 0; y < 240; ++y) {
        for (size_t x = 0; x < 320; ++x) {
            Tex3DS::RGBA& px = img.pixels[y * img.stride + x];
            px.r = 255; px.g = 128; px.b = 0; px.a = 255;
        }
    }

    // 2. Set conversion parameters
    Tex3DS::Params params;
    params.input_img          = std::move(img);
    params.output_path        = "output.t3x";
    params.process_format     = Tex3DS::RGB565;
    params.compression_format = Tex3DS::COMPRESSION_LZ11;

    // 3. Convert and write
    bool ok = Tex3DS::Process(params);
    return ok ? 0 : 1;
}
```

> **Note:** The `RGBA` struct stores channels in memory order **B, G, R, A** — set the named fields (`px.r`, `px.g`, …) to avoid surprises.

### Link against the library

```cmake
target_link_libraries(my_app PRIVATE tex3ds)
target_include_directories(my_app PRIVATE path/to/libtex3ds/public)
```

### API Reference

Full documentation — types, enums, pixel formats, compression formats, output file format, and constraints:  
→ [docs/api-en.md](docs/api-en.md)

### License

libtex3ds is licensed under the **GNU GPL v3**.  
The bundled ETC1 codec (`rg_etc1`) is licensed under the **zlib license**.

---

[Back to top](#libtex3ds)

---

<a id="français"></a>

## 🇫🇷 Français

Bibliothèque statique C++11 pour convertir des données de pixels RGBA au format de texture natif de la Nintendo 3DS (`.t3x`).

Elle implémente un sous-ensemble sous forme de bibliothèque de l'outil en ligne de commande [`tex3ds`](https://github.com/devkitPro/tex3ds) (créé par Michael Theall / mtheall ; ce fork par ds-sloth, 2024).

### Prérequis

- CMake ≥ 3.2
- Un compilateur compatible C++11 (GCC, Clang, MSVC)
- Aucune dépendance externe — la bibliothèque est entièrement autonome

### Compilation

```sh
# Via le script fourni
./build.sh

# Ou manuellement
mkdir -p build
cmake -S . -B build
make -C build
```

L'archive statique `libtex3ds.a` est produite dans `build/` (et copiée à la racine du dépôt par `build.sh`).

#### Installation

```sh
cmake --install build
```

Installe `libtex3ds.a` dans `lib/` et `public/libtex3ds.h` dans `include/` selon les chemins standard `GNUInstallDirs`.

### Démarrage rapide

```cpp
#include "libtex3ds.h"

int main() {
    // 1. Créer une image et remplir les pixels
    Tex3DS::Image img(320, 240);
    for (size_t y = 0; y < 240; ++y) {
        for (size_t x = 0; x < 320; ++x) {
            Tex3DS::RGBA& px = img.pixels[y * img.stride + x];
            px.r = 255; px.g = 128; px.b = 0; px.a = 255;
        }
    }

    // 2. Définir les paramètres de conversion
    Tex3DS::Params params;
    params.input_img          = std::move(img);
    params.output_path        = "output.t3x";
    params.process_format     = Tex3DS::RGB565;
    params.compression_format = Tex3DS::COMPRESSION_LZ11;

    // 3. Convertir et écrire
    bool ok = Tex3DS::Process(params);
    return ok ? 0 : 1;
}
```

> **Note :** La struct `RGBA` stocke les canaux en mémoire dans l'ordre **B, G, R, A** — utilisez toujours les champs nommés (`px.r`, `px.g`, …) pour éviter les erreurs.

### Lier la bibliothèque

```cmake
target_link_libraries(mon_app PRIVATE tex3ds)
target_include_directories(mon_app PRIVATE chemin/vers/libtex3ds/public)
```

### Référence API

Documentation complète — types, énumérations, formats de pixels, formats de compression, format du fichier de sortie et contraintes :  
→ [docs/api-fr.md](docs/api-fr.md)

### Licence

libtex3ds est licencié sous la **GNU GPL v3**.  
Le codec ETC1 intégré (`rg_etc1`) est licencié sous la **licence zlib**.

---

[Retour en haut](#libtex3ds)
