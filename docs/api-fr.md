# libtex3ds — Référence API (Français)

> **Language / Langue:** [English](api-en.md) | [Français](api-fr.md)  
> Retour au [README](../README.md)

---

## Table des matières

- [Types](#types)
  - [Quantum](#quantum)
  - [RGBA](#rgba)
  - [Image](#image)
- [Énumérations](#énumérations)
  - [ProcessFormat](#processformat)
  - [CompressionFormat](#compressionformat)
  - [etc1\_quality](#etc1_quality)
- [Params](#params)
- [Process()](#process)
- [Exemples](#exemples)
- [Contraintes et limitations](#contraintes-et-limitations)
- [Format du fichier de sortie](#format-du-fichier-de-sortie)

---

## Types

### `Quantum`

```cpp
using Tex3DS::Quantum = uint8_t;
static constexpr uint8_t Tex3DS::QuantumRange = 255;
```

Représente la valeur d'un canal de couleur dans l'intervalle `[0, 255]`.

---

### `RGBA`

```cpp
struct Tex3DS::RGBA {
    Quantum b, g, r, a;
};
```

Un pixel. Malgré le nom, les champs sont stockés en mémoire dans l'ordre **B, G, R, A** pour correspondre à la convention little-endian de la 3DS. Utilisez toujours les champs nommés pour éviter les erreurs :

```cpp
Tex3DS::RGBA px;
px.r = 255; px.g = 128; px.b = 0; px.a = 255;
```

---

### `Image`

```cpp
struct Tex3DS::Image {
    size_t stride = 0;          // largeur d'une ligne en pixels (généralement == w)
    size_t w      = 0;          // largeur de l'image en pixels
    size_t h      = 0;          // hauteur de l'image en pixels
    std::vector<RGBA> pixels;   // données ligne par ligne, taille = stride * h

    Image() = default;
    Image(size_t w, size_t h);  // alloue w*h pixels initialisés à zéro
};
```

Accédez aux pixels via `img.pixels[y * img.stride + x]`.

---

## Énumérations

### `ProcessFormat`

Le format d'encodage des pixels écrit dans le fichier `.t3x`.

| Valeur | Bits/px | Description |
|---|---|---|
| `RGBA8888` | 32 | Couleur complète + alpha complet. Ordre en mémoire : A, B, G, R. |
| `RGB888` | 24 | Couleur complète, sans alpha (forcé à 255). Ordre en mémoire : B, G, R. |
| `RGBA5551` | 16 | R, G, B sur 5 bits + alpha sur 1 bit. |
| `RGB565` | 16 | R sur 5 bits, G sur 6 bits, B sur 5 bits. Sans alpha. |
| `RGBA4444` | 16 | 4 bits par canal. |
| `LA88` | 16 | Luminance (8 bits) + alpha (8 bits). Ordre en mémoire : alpha, luminance. |
| `HILO88` | 16 | Canal rouge → octet HI, canal vert → octet LO. Bleu et alpha ignorés. |
| `L8` | 8 | Luminance uniquement. Alpha ignoré. |
| `A8` | 8 | Alpha uniquement. RGB ignoré. |
| `LA44` | 8 | Luminance 4 bits + alpha 4 bits. |
| `L4` | 4 | Luminance 4 bits. Deux pixels par octet (premier pixel dans le nibble bas). |
| `A4` | 4 | Alpha 4 bits. Deux pixels par octet (premier pixel dans le nibble bas). |
| `ETC1` | 4 | Compression par blocs ETC1. Sans alpha. |
| `ETC1A4` | 8 | Compression par blocs ETC1 + bloc alpha 4 bits. |
| `AUTO_L8` | — | Alias de `LA88` en mode bibliothèque. |
| `AUTO_L4` | — | Alias de `LA44` en mode bibliothèque. |
| `AUTO_ETC1` | — | Alias de `ETC1A4` en mode bibliothèque. |

La luminance est calculée avec les coefficients ITU-R BT.709 (R : 0,2127, G : 0,7152, B : 0,0722) et une correction gamma sRGB correcte.

> **Choisir un format :**
> - Utilisez `RGB565` ou `RGB888` pour les images entièrement opaques.
> - Utilisez `RGBA4444` ou `RGBA5551` pour les images avec transparence simple.
> - Utilisez `ETC1` / `ETC1A4` pour la compression maximale, au prix d'un temps d'encodage plus long.
> - Utilisez `L8` / `LA88` pour les assets en niveaux de gris ou les icônes.

---

### `CompressionFormat`

Compression secondaire appliquée au bloc de pixels encodés avant l'écriture sur disque.

| Valeur | Description |
|---|---|
| `COMPRESSION_NONE` | Aucune compression. Les données sont encapsulées dans un en-tête GBA de 4 octets. |
| `COMPRESSION_LZ10` | LZSS / LZ10. Correspondance max : 18 octets, déplacement max : 4096 octets. |
| `COMPRESSION_LZ11` | LZ11. Correspondance max : 65 808 octets, déplacement max : 4096 octets. |
| `COMPRESSION_RLE` | Encodage par plages (RLE). Plage min : 3 octets, plage max : 130 octets. |
| `COMPRESSION_HUFF` | Codage de Huffman 8 bits. |
| `COMPRESSION_AUTO` | Essaie les cinq méthodes, affiche la gagnante sur stdout et choisit la sortie la plus petite. |

> `COMPRESSION_LZ11` est un bon choix par défaut pour la plupart des textures. Utilisez `COMPRESSION_AUTO` quand la taille de sortie prime sur le temps de compilation.

---

### `rg_etc1::etc1_quality`

```cpp
enum rg_etc1::etc1_quality {
    cLowQuality,
    cMediumQuality,
    cHighQuality,
};
```

Contrôle le compromis qualité/vitesse de l'encodeur ETC1. Utilisé uniquement quand `process_format` vaut `ETC1`, `ETC1A4` ou `AUTO_ETC1`.

| Valeur | Vitesse | Qualité |
|---|---|---|
| `cLowQuality` | Rapide | Basse |
| `cMediumQuality` | Modérée | Bonne (défaut) |
| `cHighQuality` | Lente | Maximale |

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

| Champ | Type | Défaut | Description |
|---|---|---|---|
| `output_path` | `std::string` | `""` | Chemin du fichier `.t3x` en sortie. Si vide, l'encodage est fait en mémoire sans écriture sur disque. |
| `process_format` | `ProcessFormat` | `RGBA8888` | Format d'encodage des pixels cible. |
| `etc1_quality` | `etc1_quality` | `cMediumQuality` | Qualité de l'encodeur ETC1. Ignoré pour les formats non-ETC1. |
| `compression_format` | `CompressionFormat` | `COMPRESSION_AUTO` | Compression appliquée aux données pixels. |
| `input_img` | `Image` | — | L'image source. **Doit être renseignée avant d'appeler `Process`.** |

---

## `Process()`

```cpp
bool Tex3DS::Process(const Tex3DS::Params& params);
```

Convertit l'image source et écrit un fichier `.t3x`.

**Retourne** `true` en cas de succès, `false` en cas d'erreur (les détails sont affichés sur `stderr`).

**Étapes internes :**

1. Valide que `w` et `h` sont tous les deux ≤ 1024.
2. Étend le canevas à la prochaine puissance de deux dans chaque dimension (minimum 8×8). La zone ajoutée est initialisée à zéro.
3. Calcule les coordonnées UV normalisées de la sous-image visible dans le canevas étendu.
4. Applique la disposition en tuiles Morton/Z-order (swizzle) au tableau de pixels (ignoré pour ETC1/ETC1A4 qui tile en interne).
5. Encode les pixels tuile par tuile en blocs de 8×8 pixels selon le `ProcessFormat` choisi.
6. Applique le `CompressionFormat` choisi aux données encodées.
7. Si `output_path` n'est pas vide : écrit le fichier binaire `.t3x` (en-tête + données compressées).

**Exemple :**

```cpp
Tex3DS::Params params;
params.input_img          = std::move(monImage);
params.output_path        = "textures/icone.t3x";
params.process_format     = Tex3DS::RGBA4444;
params.compression_format = Tex3DS::COMPRESSION_LZ11;

if (!Tex3DS::Process(params)) {
    // vérifier stderr pour le message d'erreur
}
```

---

## Exemples

### 0. Conversion simple d'un PNG (stb_image)

libtex3ds ne charge pas les images lui-même — il faut décoder le PNG au préalable.  
La solution la plus simple est [`stb_image.h`](https://github.com/nothings/stb/blob/master/stb_image.h) (un seul fichier header, aucune dépendance — il suffit de le copier dans votre projet).

**PNG opaque → RGB565 :**

```cpp
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#include "libtex3ds.h"

bool pngVersT3x(const char* chemin_png, const char* chemin_sortie) {
    int w, h, channels;
    uint8_t* data = stbi_load(chemin_png, &w, &h, &channels, 4); // force RGBA
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
    params.output_path    = chemin_sortie;
    params.process_format = Tex3DS::RGB565;

    return Tex3DS::Process(params);
}
```

**PNG avec transparence → RGBA4444 :**

```cpp
bool pngTransparentVersT3x(const char* chemin_png, const char* chemin_sortie) {
    int w, h, channels;
    uint8_t* data = stbi_load(chemin_png, &w, &h, &channels, 4);
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
    params.output_path    = chemin_sortie;
    params.process_format = Tex3DS::RGBA4444; // conserve l'alpha
    // utilisez RGBA8888 si vous avez besoin d'une précision alpha maximale

    return Tex3DS::Process(params);
}
```

> `stbi_load` produit toujours les pixels dans l'ordre mémoire R, G, B, A avec la lecture forcée à 4 canaux — mappez-les directement sur `px.r/g/b/a`.

---

### 1. Texture de fond opaque (RGB565)

Meilleur format pour les images entièrement opaques — 16 bpp, sans alpha, bonne qualité.

```cpp
#include "libtex3ds.h"

// raw_pixels est un tableau uint8_t plat de bytes RGBA (4 octets par pixel)
// avec les dimensions 512x256, déjà chargé depuis un décodeur PNG ou similaire.
bool convertirFond(const uint8_t* raw_pixels, size_t w, size_t h) {
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
    params.output_path        = "fond.t3x";
    params.process_format     = Tex3DS::RGB565;
    params.compression_format = Tex3DS::COMPRESSION_LZ11;

    return Tex3DS::Process(params);
}
```

---

### 2. Feuille de sprites avec transparence (RGBA4444)

4 bits par canal — divise la mémoire par deux par rapport à RGBA8888, idéal pour les sprites UI avec des bords doux.

```cpp
bool convertirSprites(const uint8_t* raw_pixels, size_t w, size_t h) {
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

### 3. Texture compressée haute qualité (ETC1A4)

ETC1A4 offre le meilleur taux de compression pour les textures opaques ou semi-transparentes. Utilisez `cHighQuality` pour les builds finaux, `cLowQuality` pour les itérations rapides.

```cpp
bool convertirCompresse(const uint8_t* raw_pixels, size_t w, size_t h, bool buildFinal) {
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
    params.etc1_quality       = buildFinal ? rg_etc1::cHighQuality
                                           : rg_etc1::cLowQuality;
    params.compression_format = Tex3DS::COMPRESSION_LZ11;

    return Tex3DS::Process(params);
}
```

---

### 4. Atlas de police en niveaux de gris (L8)

Canal luminance unique — idéal pour les bitmaps de polices monochromes ou les shadow maps.

```cpp
bool convertirPolice(const uint8_t* pixels_gris, size_t w, size_t h) {
    // pixels_gris est 1 octet par pixel (niveaux de gris)
    Tex3DS::Image img(w, h);

    for (size_t y = 0; y < h; ++y) {
        for (size_t x = 0; x < w; ++x) {
            Tex3DS::RGBA& px = img.pixels[y * img.stride + x];
            px.r = pixels_gris[y * w + x];
            px.g = px.r;
            px.b = px.r;
            px.a = 255;
        }
    }

    Tex3DS::Params params;
    params.input_img          = std::move(img);
    params.output_path        = "police.t3x";
    params.process_format     = Tex3DS::L8;
    params.compression_format = Tex3DS::COMPRESSION_RLE; // les polices se compressent bien en RLE

    return Tex3DS::Process(params);
}
```

---

### 5. Encodage en mémoire sans écriture sur disque

Mettre `output_path` à `""` lance le pipeline d'encodage complet sans toucher le disque.  
Utile pour valider des paramètres ou profiler.

```cpp
bool validerEncodage(Tex3DS::Image img) {
    Tex3DS::Params params;
    params.input_img          = std::move(img);
    params.output_path        = "";              // aucun fichier écrit
    params.process_format     = Tex3DS::RGBA8888;
    params.compression_format = Tex3DS::COMPRESSION_NONE;

    return Tex3DS::Process(params);
}
```

---

### 6. Conversion par lot d'une liste de fichiers

```cpp
#include "libtex3ds.h"
#include <vector>
#include <string>

struct TacheTexture {
    Tex3DS::Image         image;
    std::string           output_path;
    Tex3DS::ProcessFormat format;
};

bool convertirEnLot(std::vector<TacheTexture> taches) {
    for (auto& tache : taches) {
        Tex3DS::Params params;
        params.input_img          = std::move(tache.image);
        params.output_path        = tache.output_path;
        params.process_format     = tache.format;
        params.compression_format = Tex3DS::COMPRESSION_LZ11;

        if (!Tex3DS::Process(params)) {
            // Process() a déjà affiché l'erreur sur stderr
            return false;
        }
    }
    return true;
}
```

---

## Contraintes et limitations

| Contrainte | Détail |
|---|---|
| Taille d'entrée maximale | 1024 × 1024 pixels |
| Taille de sortie minimale | 8 × 8 pixels (les entrées plus petites sont complétées) |
| Alignement puissance de deux | Les dimensions sont toujours arrondies à la puissance de deux supérieure en interne |
| Ordre des champs RGBA | Les champs sont en ordre mémoire **B, G, R, A** — utilisez toujours les champs nommés |
| Thread-safety ETC1 | `pack_etc1_block_init()` est appelé automatiquement par `Process` mais n'est **pas thread-safe**. N'appelez pas `Process` avec un format ETC1 simultanément depuis plusieurs threads. |
| Pas de génération de mipmaps | Le nombre de mipmaps est fixé à 0 |
| Pas de chargement d'image | L'appelant doit fournir des pixels RGBA déjà décodés |
| `AUTO_L*` / `AUTO_ETC1` | En mode bibliothèque, ces valeurs sont identiques à `LA88`, `LA44` et `ETC1A4` (la logique de sélection automatique du CLI n'est pas disponible) |
| `COMPRESSION_AUTO` | Affiche la méthode de compression choisie sur stdout en tant qu'effet de bord |

---

## Format du fichier de sortie

Quand `output_path` est renseigné, `Process` écrit un fichier binaire `.t3x` avec la structure suivante.

### En-tête

| Offset | Taille | Champ |
|---|---|---|
| 0 | 2 octets | `uint16_t` — nombre de sous-images (toujours `1`) |
| 2 | 1 octet | Paramètres de texture : bits `[2:0]` = `log2(largeur_padded) − 3`, bits `[5:3]` = `log2(hauteur_padded) − 3` |
| 3 | 1 octet | Valeur de l'enum `ProcessFormat` (`0x00`–`0x0D`) |
| 4 | 1 octet | Nombre de mipmaps (toujours `0`) |

### Enregistrement par sous-image (présent une fois)

| Taille | Champ |
|---|---|
| 2 octets | Largeur en pixels de l'image originale (non étendue) |
| 2 octets | Hauteur en pixels de l'image originale (non étendue) |
| 2 octets | Coordonnée U gauche × 1024 (virgule fixe) |
| 2 octets | Coordonnée V haute × 1024 (virgule fixe) |
| 2 octets | Coordonnée U droite × 1024 (virgule fixe) |
| 2 octets | Coordonnée V basse × 1024 (virgule fixe) |

### Bloc de données

En-tête de compression GBA suivi des données compressées, aligné sur 4 octets.

**En-tête de compression** (4 octets normalement, 8 octets si la taille non compressée ≥ 16 Mo) :

| Octet(s) | Contenu |
|---|---|
| 0 | Type de compression : `0x00` aucune, `0x10` LZ10, `0x11` LZ11, `0x28` Huffman, `0x30` RLE |
| 1–3 | Taille des données non compressées (entier 24 bits little-endian) |
