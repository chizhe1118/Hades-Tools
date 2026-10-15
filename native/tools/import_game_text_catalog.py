"""Import official Hades zh-CN display names into the editable catalog.

The game ships SJSON text tables with stable Id values. This tool reads only
the text tables used by the trainer catalog, replaces matching ``zh`` values,
and leaves internal runtime-only identifiers untouched. A JSON report records
every matched and unmatched catalog key.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import sjson


TEXT_FILES = (
    "HelpText.zh-CN.sjson",
    "CodexText.zh-CN.sjson",
    "MiscText.zh-CN.sjson",
    "MacroText.zh-CN.sjson",
    "LaunchText.zh-CN.sjson",
)

# Runtime resource ids use short names, while the text table uses the id shown
# in the codex/help text. Keep this explicit so a missing mapping is visible.
RESOURCE_TEXT_IDS = {
    "Gems": "GemDrop",
    "GiftPoints": "GiftDrop",
    "LockKeys": "LockKeyDrop",
    "MetaPoints": "RoomRewardMetaPointDrop",
    "SuperGems": "SuperGemDrop",
    "SuperGiftPoints": "SuperGiftDrop",
    "SuperLockKeys": "SuperLockKeyDrop",
}


def load_display_names(text_root: Path) -> dict[str, str]:
    names: dict[str, str] = {}
    for filename in TEXT_FILES:
        path = text_root / filename
        if not path.is_file():
            continue
        document = sjson.loads(path.read_text(encoding="utf-8"))
        for entry in document.get("Texts", []):
            key = entry.get("Id")
            value = entry.get("DisplayName")
            if isinstance(key, str) and isinstance(value, str) and value.strip():
                names.setdefault(key, value.strip())
    return names


def import_catalog(catalog: dict[str, Any], names: dict[str, str]) -> dict[str, Any]:
    matched: list[dict[str, str]] = []
    unmatched: list[dict[str, str]] = []
    for category, rows in catalog["categories"].items():
        for key, row in rows.items():
            text_key = RESOURCE_TEXT_IDS.get(key, key)
            value = names.get(text_key)
            if value:
                row["zh"] = value
                row["source"] = "game-official-zh-CN"
                matched.append({"category": category, "key": key, "textKey": text_key})
            else:
                unmatched.append({"category": category, "key": key, "textKey": text_key})
    return {"matched": matched, "unmatched": unmatched}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--text-root", type=Path, required=True)
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    catalog = json.loads(args.catalog.read_text(encoding="utf-8"))
    names = load_display_names(args.text_root)
    report = import_catalog(catalog, names)
    catalog["metadata"].update(
        {
            "status": "official-game-zh-CN",
            "source": "Hades Content/Game/Text/zh-CN",
            "updatedAt": datetime.now(timezone.utc).isoformat(),
            "instructions": "Official zh-CN display names are imported by text key; unmatched runtime identifiers remain unchanged.",
        }
    )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    args.report.write_text(
        json.dumps(
            {
                "generatedAt": datetime.now(timezone.utc).isoformat(),
                "textRoot": str(args.text_root),
                "textFileCount": len([name for name in TEXT_FILES if (args.text_root / name).is_file()]),
                "availableTextIds": len(names),
                **report,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"Imported {len(report['matched'])} official names; {len(report['unmatched'])} keys remain unmatched.")


if __name__ == "__main__":
    main()
