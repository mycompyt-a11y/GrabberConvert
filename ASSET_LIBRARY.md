# Publishing GrabberConvert on the Godot Asset Library

Official guide: [Submitting to the Asset Library](https://docs.godotengine.org/en/latest/community/asset_library/submitting_to_assetlib.html)

Sign in at [godotengine.org/asset-library](https://godotengine.org/asset-library/) before submitting.

---

## Requirements checklist (official)

| Requirement | Status |
|-------------|--------|
| Asset works in stated Godot version | Test on **4.4+** before submit |
| Proper `.gitignore` (excludes `.godot/`) | Done |
| No essential git submodules | Done |
| `LICENSE` in repo root with copyright | Done (`MIT`, Thumbnail Grabber 2026) |
| License matches submission form | Use **MIT** |
| English name and description | Done (`GrabberConvert`) |
| Icon URL is direct (`raw.githubusercontent.com`) | You provide at submit time (see below) |
| Files in `addons/grabber_convert/` | Done |
| `LICENSE` + `README` copied into plugin folder | Done |
| No `.gitignore` inside `addons/grabber_convert/` | Done (root `.gitignore` only) |
| `.gitattributes` `export-ignore` (addons-only ZIP) | Done |
| Script warnings fixed in addon code | Done (unused code removed) |
| Screenshots folder has `.gdignore` | Done (`screenshots/.gdignore`) |

---

## Before you push to GitHub

1. **Remove local secrets/paths** — Do not commit `[grabber_convert]` paths in `project.godot` (ImageMagick/FFmpeg on your PC). The demo project ships with the plugin **disabled**.
2. **No test images** — `.gitignore` excludes `test_out*`, `20260205_*`, `*.heic`.
3. **Add screenshots** — Export 1–3 PNGs into `screenshots/` for the Asset Library preview form.
4. **Add icon PNG** — Export `addons/grabber_convert/icon.svg` to **128×128 PNG** as `screenshots/icon.png`.

---

## Submit form (copy-paste)

| Field | Value |
|-------|--------|
| **Asset Name** | GrabberConvert |
| **Category** | Addons, Tools |
| **Godot version** | 4.4 |
| **Version** | 1.0.0 |
| **License** | MIT |
| **Repository URL** | `https://github.com/mycompyt-a11y/GrabberConvert` |
| **Issues URL** | `https://github.com/mycompyt-a11y/GrabberConvert/issues` |

**Short description:**

```
Convert HEIC, HEIF, AVIF and other images to JPG, PNG, WebP, or BMP inside the Godot editor.
```

**Icon URL** (after push):

```
https://raw.githubusercontent.com/mycompyt-a11y/GrabberConvert/master/screenshots/icon.png
```

Icon must be square, minimum 128x128, PNG or JPG.

---

## Project links

- [Thumbnail Grabber](https://thumbnailgrabber.net/)
- [Web HEIC converter](https://thumbnailgrabber.net/heic-converter)
- [Contact](https://thumbnailgrabber.net/contact)
