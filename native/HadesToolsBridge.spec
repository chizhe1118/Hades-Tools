# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_all

datas = [('../analysis/hades_trainer/hades_runtime_profile.json', '.'), ('../analysis/hades_trainer/hades_tools_runtime.js', '.'), ('../analysis/hades_trainer/hades_tools_commands.lua', '.'), ('../analysis/hades_trainer/hades_tools_json.lua', '.'), ('../analysis/hades_trainer/hades_tools_ui.html', '.')]
binaries = []
hiddenimports = []
tmp_ret = collect_all('frida')
datas += tmp_ret[0]; binaries += tmp_ret[1]; hiddenimports += tmp_ret[2]


a = Analysis(
    ['..\\analysis\\hades_trainer\\hades_tools_backend.py'],
    pathex=[],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='HadesToolsBridge',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='HadesToolsBridge',
)
