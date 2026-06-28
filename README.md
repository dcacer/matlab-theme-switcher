# MATLAB Theme Switcher 🎨

Easily apply custom editor color themes in MATLAB — including **Dracula**, **Solarized**, **Catppuccin**, and more — by modifying your `.mlsettings` file. Built entirely in MATLAB with no external dependencies.

---

## ✅ Features

- Supports popular themes: Dracula, Solarized, Catppuccin, Monokai
- Compatible with **MATLAB R2025a** and newer
- Pure MATLAB — no Java hacks or toolboxes required
- Automatically backs up your current theme
- Fully editable and extensible theme system

---

## 🚀 Usage

1. Clone or download this repo:
   ```bash
   git clone https://github.com/dcacer/matlab-theme-switcher.git
   cd matlab-theme-switcher
   ```

2. Open `colorThemeSwitcher.m` in MATLAB

3. Set the desired theme at the top:
   ```matlab
   themeName = 'catppuccin';  % Options: 'dracula', 'solarized', 'monokai'
   ```

4. Run the script (MATLAB can stay open). It applies the theme through
   MATLAB's **Settings API** (`settings().PersonalValue`), so MATLAB itself
   owns and persists the change.

5. **Restart MATLAB** to fully redraw the desktop with the new colors

> **Why the Settings API?** MATLAB keeps all settings in memory while running
> and writes `matlab.mlsettings` back to disk on shutdown. Editing the
> `.mlsettings` file directly while MATLAB is open does not work — MATLAB
> overwrites it with its in-memory copy on exit, so the theme *reverts* after a
> restart. Writing through `settings().PersonalValue` avoids this entirely.
> (A file-based fallback is still included for environments where the API path
> is unavailable; it must be copied into `prefdir` while MATLAB is closed.)

---

## 🎨 Available Themes

| Theme         | Description                          | Source                                      |
|---------------|--------------------------------------|---------------------------------------------|
| `dracula`     | Dark, high contrast, hacker vibe     | [draculatheme.com](https://draculatheme.com) |
| `solarized`   | Low-contrast, scientifically designed| [solarized](https://ethanschoonover.com/solarized/) |
| `catppuccin`  | Soft pastel aesthetics (Mocha)       | [catppuccin.com](https://github.com/catppuccin) |
| `monokai`     | Legendary syntax theme               | Inspired by [monokai.pro](https://monokai.pro/) |

Add more themes easily via `getTheme.m`.

---

## 📂 Project Structure

```
matlab-theme-switcher/
├── colorThemeSwitcher.m         # Main script (Settings API + file fallback)
├── getTheme.m                   # Theme definitions
├── parseGenericSettingsJson.m  # Helper for .json parsing
├── README.md                    # You’re reading it
├── LICENSE                      # MIT License
└── mlsettings_tmp/              # Auto-generated temporary folder
```

---

## 📄 Tested Environment

- MATLAB **R2025a**
- Windows 11
- Uses built-in `zip`, `jsonencode`, `jsondecode`, `prefdir` APIs

---

## 👤 Author

Developed by **[@dcacer](https://github.com/dcacer)**  
For questions or contributions

---

## 🧾 License

This project is licensed under the [MIT License](LICENSE).

---

## 🎨 Theme Licenses and Credits

- **Dracula** — © Zeno Rocha — [MIT License](https://github.com/dracula/dracula-theme/blob/master/LICENSE)
- **Solarized** — © Ethan Schoonover — [MIT License](https://github.com/altercation/solarized/blob/master/LICENSE)
- **Catppuccin** — © Catppuccin Org — [MIT License](https://github.com/catppuccin/catppuccin/blob/main/LICENSE)
- **Monokai** — by Wimer Hazenberg — unofficial port, [monokai.pro](https://monokai.pro)

---

## 🙌 Contributions Welcome

- Add more themes via `getTheme.m`
- Fix encoding quirks in `.mlsettings`
- Star ⭐ the repo if you find it helpful!

---

## 🙌 Shout-out

Big thanks to [ChatGPT](https://openai.com/chatgpt) for saving hours of trial-and-error — from JSON escaping to color scheme formatting and writing this README file ☕
