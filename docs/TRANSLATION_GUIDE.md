# LDtk Internationalization & Translation Guide (多语言本地化指南)

LDtk supports full multi-language localization (i18n) based on standard GNU gettext `.po` catalogs and automatic non-invasive DOM localization.

---

## 1. Architecture Overview (多语言架构概述)

The localization system consists of three core components:

1. **`res/lang/*.po` catalogs**:
   - Standard GNU gettext format.
   - Compatible with translation editors like [Poedit](https://poedit.net/), Weblate, and Crowdin.
   - Contains `msgid` (original English string) and `msgstr` (translated string).
   - Missing translations automatically fall back to the original English text without breaking.

2. **`src/electron.renderer/Lang.hx`**:
   - Manages language registry (`Lang.LANGUAGES`), current active locale (`Lang.CUR`), and GetText dictionary.
   - Supports both embedded resources (`hxd.Res`) and external runtime files (`res/lang/*.po` or `app/assets/lang/*.po`).
   - `Lang.getText(str)` provides whitespace-normalized lookup for dynamic code strings.
   - `Lang.localizeDom(jCtx)` automatically traverses and translates HTML templates, labels, buttons, headers, tooltips (`title`), and `<info>` bubbles.

3. **`src/electron.common/Settings.hx` & `ui.modal.dialog.EditAppSettings`**:
   - Persists user language choice in `settings.json` under `locale`.
   - Auto-detects system language from `navigator.language` (e.g. defaults to `zh-CN` in Chinese environments).
   - Allows changing language directly from the **Application Settings (F12)** dialog.

---

## 2. How to Add a New Language (如何添加新语言)

Adding a new language (e.g., Japanese `ja`, French `fr`, Spanish `es`, German `de`, etc.) is designed to be straightforward and requires only **two simple steps**:

### Step 1: Create the Translation Catalog (`.po` 文件)
1. Copy the template catalog:
   ```bash
   cp res/lang/sourceTexts.pot res/lang/[lang_code].po
   # Example for Japanese:
   cp res/lang/sourceTexts.pot res/lang/ja.po
   ```
2. Open `res/lang/[lang_code].po` in [Poedit](https://poedit.net/) or any text editor.
3. Fill in the `msgstr` translations for each `msgid`.

### Step 2: Register the Language in `Lang.hx`
In `src/electron.renderer/Lang.hx`, add your language to the `LANGUAGES` array:

```haxe
public static var LANGUAGES = [
    { id: "en", label: "English" },
    { id: "zh-CN", label: "简体中文" },
    { id: "ja", label: "日本語" }, // <-- Add your new language here
];
```

### Step 3: Recompile
```bash
# Debug build
haxe main.debug.hxml
haxe renderer.debug.hxml

# Or release build
haxe main.hxml
haxe renderer.hxml
```

---

## 3. Runtime External Translation Packs (无需重编译的外挂语言包)

LDtk can also load `.po` files directly from the filesystem at runtime!
If a file exists at `res/lang/[lang_code].po` or `app/assets/lang/[lang_code].po`, it will be loaded dynamically, allowing community contributors to test and refine translations without needing a Haxe development environment.

---

## 4. Best Practices for Developers (开发规范)

- When writing new HTML templates in `app/assets/tpl/`:
  - Simply write standard English text in tags (`<button>`, `<label>`, `<h3>`, `<info>`, `title="..."`).
  - `JsTools.parseComponents` will automatically translate them when the template loads.
- When generating strings in Haxe code:
  - For static UI strings: use `L.t._("My String")`.
  - For dynamic strings with runtime variables: use `L.t._("Hello ::name::", { name: user })` or `L.getText("My String")`.
- Run the extraction script in `scratch/extract_strings.py` whenever adding new features to keep catalogs updated.
