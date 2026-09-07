from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


def main() -> None:
    parser = argparse.ArgumentParser(description="Recover a transparent bed and soft shadow from a baked checkerboard preview.")
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    rgb = np.asarray(Image.open(args.input).convert("RGB"), dtype=np.float32)
    red, green, blue = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    maximum = rgb.max(axis=2)
    minimum = rgb.min(axis=2)
    chroma = maximum - minimum
    luminance = (red + green + blue) / 3.0
    red_blue_delta = np.abs(red - blue)
    row = np.arange(rgb.shape[0], dtype=np.float32)[:, None]
    column = np.arange(rgb.shape[1], dtype=np.float32)[None, :]
    white_bedding_region = (
        (row < rgb.shape[0] * 0.56)
        & (column > rgb.shape[1] * 0.12)
        & (column < rgb.shape[1] * 0.62)
        & (row < column * 0.45 + rgb.shape[0] * 0.35)
    )

    # The checkerboard is bright and neutral. Bed materials are either clearly
    # colored (wood/blanket) or subtly warm (white pillow and sheet).
    subject = (
        (chroma > 38.0)
        | ((luminance > 215.0) & (red_blue_delta > 6.0) & white_bedding_region)
        | ((luminance <= 215.0) & (chroma > 30.0))
    )

    # Close tiny classification gaps without expanding the silhouette.
    subject_image = Image.fromarray((subject * 255).astype(np.uint8), mode="L")
    # A wider morphological close restores neutral seams/details inside the
    # white bedding, but deliberately does not fill the large open region under
    # the bed where the reconstructed diffuse shadow belongs.
    subject_image = subject_image.filter(ImageFilter.MaxFilter(15)).filter(ImageFilter.MinFilter(15))
    hard_subject = np.asarray(subject_image, dtype=np.float32) / 255.0
    # Pull the matte one pixel inward before feathering, eliminating the white
    # checker fringe that was baked into the source antialiasing.
    subject_image = subject_image.filter(ImageFilter.MinFilter(3))
    hard_subject = np.asarray(subject_image, dtype=np.float32) / 255.0
    soft_subject = np.asarray(subject_image.filter(ImageFilter.GaussianBlur(0.85)), dtype=np.float32) / 255.0

    # The generated diffuse shadow contains the checker pattern, so discard it
    # and rebuild a clean, subtle floor shadow on true transparency.
    height, width = subject.shape
    diffuse = Image.new("L", (width, height), 0)
    diffuse_draw = ImageDraw.Draw(diffuse)
    diffuse_draw.polygon(
        [
            (int(width * 0.09), int(height * 0.43)),
            (int(width * 0.56), int(height * 0.95)),
            (int(width * 0.94), int(height * 0.74)),
            (int(width * 0.40), int(height * 0.27)),
        ],
        fill=42,
    )
    diffuse = diffuse.filter(ImageFilter.GaussianBlur(max(12, int(width * 0.016))))
    contact = Image.new("L", (width, height), 0)
    contact_draw = ImageDraw.Draw(contact)
    for cx, cy in [(0.12, 0.48), (0.58, 0.88), (0.90, 0.70)]:
        rx, ry = int(width * 0.030), int(height * 0.018)
        px, py = int(width * cx), int(height * cy)
        contact_draw.ellipse((px - rx, py - ry, px + rx, py + ry), fill=86)
    contact = contact.filter(ImageFilter.GaussianBlur(max(4, int(width * 0.005))))
    shadow_alpha = np.maximum(np.asarray(diffuse, dtype=np.float32), np.asarray(contact, dtype=np.float32)) / 255.0
    shadow_alpha *= 1.0 - hard_subject

    subject_alpha = soft_subject
    final_alpha = subject_alpha + shadow_alpha * (1.0 - subject_alpha)

    subject_rgb = rgb
    shadow_rgb = np.zeros_like(rgb)
    shadow_rgb[..., 0] = 82.0
    shadow_rgb[..., 1] = 62.0
    shadow_rgb[..., 2] = 45.0
    denominator = np.maximum(final_alpha[..., None], 1.0 / 255.0)
    final_rgb = (
        subject_rgb * subject_alpha[..., None]
        + shadow_rgb * shadow_alpha[..., None] * (1.0 - subject_alpha[..., None])
    ) / denominator

    rgba = np.dstack((np.clip(final_rgb, 0, 255), np.clip(final_alpha * 255.0, 0, 255))).astype(np.uint8)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba, mode="RGBA").save(args.output)


if __name__ == "__main__":
    main()
