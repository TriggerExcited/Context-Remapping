# Context-Remapping
Repository for an image scaling technique I'm working on.

## grow2x
A simple implementation of context remapping where the context image (here, original) is remapped on a DDT interpolated copy of itself.
Works for pixel art and retro images. Looks similar to other retro scaling techniques like scale2x and scalefx that keep the original colors.
It preserves the original image better and skips on common artifacts caused by this type of scaling techniques like turning dither-like patterns into noodles while introducing its own artifacts in the form of missing color in thin lines.
It does stack but the quality of the edges is reduced every pass.

## License
MIT
