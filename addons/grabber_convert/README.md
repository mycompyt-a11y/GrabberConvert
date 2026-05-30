# GrabberConvert

Godot editor plugin by [Thumbnail Grabber](https://thumbnailgrabber.net/). Converts **HEIC**, **HEIF**, **AVIF**, and other images to **JPG**, **PNG**, **WebP**, or **BMP** inside the editor.

## Requirements

- Godot **4.4+** (tested on 4.6)
- **ImageMagick** or **FFmpeg** for HEIC/HEIF/AVIF (configure under **Dependencies** tab)

## Installation

1. Copy this entire `grabber_convert` folder to `your_project/addons/grabber_convert` (do not add a `.gitignore` inside the addon folder).
2. **Project → Project Settings → Plugins** → enable **GrabberConvert**.
3. Open the **GrabberConvert** tab in the bottom panel.

## Usage

- Select images in **FileSystem** → right-click **Convert to JPG** (or PNG / WebP / BMP).
- Or use the bottom panel **Convert** tab → **Convert Selected Files**.
- Configure ImageMagick/FFmpeg under the **Dependencies** tab.

## Project settings

Settings are stored under **Project Settings → grabber_convert**.

## License

MIT License — see [LICENSE](LICENSE). Copyright © [Thumbnail Grabber](https://thumbnailgrabber.net/).

## Links

- Website: [thumbnailgrabber.net](https://thumbnailgrabber.net/)
- Web HEIC converter: [thumbnailgrabber.net/heic-converter](https://thumbnailgrabber.net/heic-converter)
- Contact: [thumbnailgrabber.net/contact](https://thumbnailgrabber.net/contact)

Source and full documentation: [github.com/mycompyt-a11y/GrabberConvert](https://github.com/mycompyt-a11y/GrabberConvert)
