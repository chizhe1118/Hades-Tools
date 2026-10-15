# Third-party sources

| Component | Version / revision | Source | License record |
| --- | --- | --- | --- |
| material-components-qml / md3.Core | 90dc5217f73cce6ea1ff936605c63e1466db6730 | https://github.com/sudoevolve/material-components-qml | Pinned upstream tree contains no root LICENSE file. `src/Core/Styles/Theme.qml` declares LGPL-3.0-or-later; the other Core files do not carry the same file header. Upstream README and source attribution are preserved; no broader license is inferred. |
| Material Color Utilities | Copy shipped in the pinned MD3 source | https://github.com/material-foundation/material-color-utilities | Apache-2.0 headers retained; licenses/Apache-2.0.txt |
| Material Icons font | MaterialIconsRound-Regular.otf shipped by MD3 | https://github.com/google/material-design-icons | Apache-2.0; licenses/Apache-2.0.txt |
| Lucide circle-alert SVG | Vendored icon from upstream main, retrieved 2026-10-14 | https://github.com/lucide-icons/lucide/blob/main/icons/circle-alert.svg | ISC and Feather MIT attribution; licenses/lucide-LICENSE |
| Lucide languages SVG | Vendored icon from upstream main, retrieved 2026-10-14 | https://github.com/lucide-icons/lucide/blob/main/icons/languages.svg | ISC and Feather MIT attribution; licenses/lucide-LICENSE |
| Qt | 6.8.3, dynamically linked | https://download.qt.io/official_releases/qt/6.8/6.8.3/submodules/ | LGPL-3.0 / GPL licenses; licenses/LGPL-3.0-only.txt, GPL-3.0-only.txt; individual module and third-party terms remain applicable. |
| GCC / MinGW runtime | 13.1.0 | https://gcc.gnu.org/ and https://www.mingw-w64.org/ | GCC runtime exception and MinGW notices included in licenses. |
| winpthreads | Qt MinGW 13.1.0 distribution | https://www.mingw-w64.org/ | licenses/winpthreads-COPYING.txt |
| Python | 3.12.5 | https://www.python.org/downloads/release/python-3125/ | licenses/Python-LICENSE.txt |
| Frida | 17.16.4 | https://github.com/frida/frida | wxWindows Library Licence 3.1; licenses/Frida-COPYING.txt |
| psutil | 7.2.2 | https://github.com/giampaolo/psutil | BSD-3-Clause; licenses/psutil-LICENSE.txt |
| PyInstaller | 6.16.0 | https://github.com/pyinstaller/pyinstaller | GPL-2.0 with bootloader exception; licenses/PyInstaller-COPYING.txt |

Qt DLLs remain separate and replaceable. The complete application source, bridge source, and build scripts are included in the source archive. Third-party terms are independent of the project's MIT license.

SimSun and Segoe UI are provided by Windows and are referenced by family name. Font binaries are not included in the distribution.

Catalog Chinese names are imported from the installed game's official `Content/Game/Text/zh-CN` SJSON tables when matching `Id` values exist. The importer uses sjson 2.1.1 (https://pypi.org/project/sjson/) and is a development tool; it is not bundled. Entries with no official text-table key retain their existing editable value, with provenance stored in `translations/catalog.zh-CN.json` and the import report under `analysis/hades_trainer/catalogs/`.

The first release uses no FLiNG trainer binary, artwork, or bundled executable in its distribution. Game-specific values come from the runtime profile and the game's own Lua data tables.
