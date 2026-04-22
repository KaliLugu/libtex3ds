#define STB_IMAGE_IMPLEMENTATION
#include "libtex3ds.h"
#include "stb_image.h"
#include <iostream>
#include <3ds.h>

int main() {
    int w, h, channels;
    uint8_t* data = stbi_load("input.png", &w, &h, &channels, 4);
    if (!data) {
        std::cerr << "Erreur lors du chargement de l'image." << std::endl;
        return 1;
    }

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
    params.output_path    = "output.t3x";
    params.process_format = Tex3DS::RGBA4444; // conserve l'alpha
    // utilisez RGBA8888 si vous avez besoin d'une précision alpha maximale

    return Tex3DS::Process(params);
}
