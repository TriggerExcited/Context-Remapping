# Context-Remapping
Repository for an image scaling technique I'm working on.

## grow2x
A simple implementation of context remapping where the context image (here, original) is remapped on a DDT interpolated copy of itself.
Works for pixel art and retro images. Looks similar to other retro scaling techniques like scale2x and scalefx that keep the original colors but it skips on common artifacts caused by this type of scaling techniques like turning dither-like patterns into noodles and preserves the original image better.
I does stack but the quality of the edges is reduced every pass.

## License
MIT
