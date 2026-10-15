"""Print release dependency versions as a JSON object for package.ps1."""

import importlib.metadata
import json
import sys


def main() -> None:
    packages = ("frida", "psutil", "PyInstaller", "cmake", "ninja", "aqtinstall")
    versions = {name: importlib.metadata.version(name) for name in packages}
    print(json.dumps({"python": sys.version.split()[0], **versions}))


if __name__ == "__main__":
    main()
