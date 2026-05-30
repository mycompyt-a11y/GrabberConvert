# GrabberConvert for Godot

**GrabberConvert** is a Godot editor plugin by [Thumbnail Grabber](https://thumbnailgrabber.net/) that converts **HEIC**, **HEIF**, **AVIF**, and other image formats to **JPG**, **PNG**, **WebP**, or **BMP** inside the editor — ideal when iPhone photos and other non-importable files need to become Godot-friendly textures.

![Godot 4.6](https://img.shields.io/badge/Godot-4.6+-478CBF?logo=godotengine&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

## Features

- **FileSystem context menu** — Right-click files → Convert to JPG / PNG / WebP / BMP
- **Editor bottom panel** — Batch convert selected files with a chosen output format
- **Dependencies tab** — Configure ImageMagick or FFmpeg paths, auto-detect, and test executables
- **Built-in conversion** — PNG, JPG, WebP, BMP, TGA, EXR, HDR via Godot’s `Image` API
- **External conversion** — HEIC, HEIF, AVIF, TIFF, PSD, GIF via ImageMagick or FFmpeg
- **HEIC visibility** — Registers extensions so HEIC/HEIF files appear in the FileSystem dock (Godot 4.4+)
- **Project settings** — Quality, overwrite, and optional delete-original behavior

## Requirements

| Requirement | Notes |
|-------------|--------|
| **Godot** | 4.4 or newer (tested on 4.6) |
| **ImageMagick** | Recommended for HEIC/HEIF ([download](https://imagemagick.org/script/download.php)) |
| **FFmpeg** | Optional fallback ([download](https://ffmpeg.org/download.html)) |

HEIC/HEIF cannot be decoded by Godot alone. Install ImageMagick (with HEIC support) or FFmpeg and configure paths under **GrabberConvert → Dependencies**.

If you do not use Godot and only need browser-based conversion, see **Related tools** at the end of this readme.

## Installation

### From Git

```bash
git clone https://github.com/YOUR_USERNAME/grabber-convert-godot.git
```

Copy the addon into your project:

```
your_project/
  addons/
    grabber_convert/    ← copy this folder only (no .gitignore inside it)
```

Keep `.gitignore` at your **game project root** only, not inside `addons/grabber_convert/`.

### Enable the plugin

1. Open your project in Godot.
2. Go to **Project → Project Settings → Plugins**.
3. Enable **GrabberConvert**.

The **GrabberConvert** tab appears in the **bottom panel** (with Output, Debugger, etc.).

## Usage

### Convert from FileSystem

1. Place images in your project (e.g. `res://photos/`).
2. Select one or more files in the **FileSystem** dock.
3. Right-click → **Convert to JPG** (or PNG / WebP / BMP).
4. Converted files are written next to the source (e.g. `photo.heic` → `photo.jpg`).
5. The FileSystem rescans automatically.

### Convert from the bottom panel

1. Open **GrabberConvert** in the bottom panel.
2. On the **Convert** tab, choose an output format.
3. Select files in FileSystem.
4. Click **Convert Selected Files**.

### Configure dependencies (HEIC / HEIF / AVIF)

1. Open **GrabberConvert** → **Dependencies** tab.
2. Set **ImageMagick** path or leave empty to search `PATH`.
3. Click **Auto-detect** or **Test ImageMagick**.
4. Click **Apply and Save Project**.

### Project menu shortcuts

- **Project → Tools → GrabberConvert — Convert Selected**
- **Project → Tools → GrabberConvert — Settings** (opens Dependencies tab)

## Project settings

Under **Project Settings → grabber_convert** (legacy key prefix `image_converter` is still read if present):

| Setting | Description |
|---------|-------------|
| `default_format` | Default output format (jpg, png, webp, bmp) |
| `jpeg_quality` | JPEG quality (0.1–1.0) |
| `webp_quality` | WebP quality (0.1–1.0) |
| `overwrite_existing` | Replace existing output files |
| `delete_original` | Remove source file after successful conversion |
| `magick_path` | Custom ImageMagick executable |
| `ffmpeg_path` | Custom FFmpeg executable |

## Supported formats

**Input (examples):** HEIC, HEIF, AVIF, TIFF, PSD, GIF, PNG, JPG, WebP, BMP, TGA, EXR, HDR  

**Output:** JPG, PNG, WebP, BMP  

## ImageMagick notes (Windows)

- Use **ImageMagick 7** (`magick.exe`), not `magick convert ...` (the word `convert` is treated as an input file in IM7).
- Install a build with **HEIC** delegate.

```powershell
magick.exe "path\to\photo.heic" -auto-orient -quality 90 "path\to\photo.jpg"
```

## Repository layout

```
addons/grabber_convert/
  plugin.cfg
  plugin.gd
  LICENSE
  README.md
  icon.svg
  image_converter_tool.gd
  image_converter_dock.gd
  image_converter_settings_panel.gd
  image_converter_context_menu.gd
  filesystem_setup.gd
```

Publishing to the [Godot Asset Library](https://godotengine.org/asset-library/asset/submit)? See [ASSET_LIBRARY.md](ASSET_LIBRARY.md) for the full checklist and submission form text.

## Contributing

Issues and pull requests are welcome. Please test on Godot 4.4+ before submitting.

## License

MIT License — see [LICENSE](LICENSE). Copyright © Thumbnail Grabber.

## Related tools (Thumbnail Grabber)

| Resource | Link |
|----------|------|
| Website | [thumbnailgrabber.net](https://thumbnailgrabber.net/) |
| Online HEIC converter (JPG, PNG, WebP, PDF) | [thumbnailgrabber.net/heic-converter](https://thumbnailgrabber.net/heic-converter) |
| Contact | [thumbnailgrabber.net/contact](https://thumbnailgrabber.net/contact) |

Use the **web HEIC converter** for browser-based conversion. Use **GrabberConvert** when assets live in a Godot `res://` project.

Questions or feedback: [contact page](https://thumbnailgrabber.net/contact).
