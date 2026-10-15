"""Generate an editable catalog name draft with installed Argos Translate.

Development tool only. The application reads the generated JSON offline.
"""
import argparse
from datetime import datetime, timezone
import importlib.metadata
import json
from pathlib import Path
import re

import argostranslate.translate
import sjson

parser = argparse.ArgumentParser()
parser.add_argument('--catalog', type=Path, required=True)
parser.add_argument('--english', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()

catalog = json.loads(args.catalog.read_text(encoding='utf-8'))
english = sjson.loads(args.english.read_text(encoding='utf-8'))
labels = {row['Id']: row['DisplayName'] for row in english['Texts'] if 'Id' in row and 'DisplayName' in row}
resource_labels = {
    'Gems': 'GemDrop', 'GiftPoints': 'GiftDrop', 'LockKeys': 'LockKeyDrop',
    'MetaPoints': 'RoomRewardMetaPointDrop', 'SuperGems': 'SuperGemDrop',
    'SuperGiftPoints': 'SuperGiftDrop', 'SuperLockKeys': 'SuperLockKeyDrop',
}
installed = argostranslate.translate.get_installed_languages()
source = next(language for language in installed if language.code == 'en')
target = next(language for language in installed if language.code == 'zh')
translator = source.get_translation(target)
result = {
    'schemaVersion': 1,
    'metadata': {
        'status': 'machine-translation-draft',
        'translator': 'Argos Translate',
        'translatorVersion': importlib.metadata.version('argostranslate'),
        'model': 'translate-en_zh-1_9',
        'createdAt': datetime.now(timezone.utc).isoformat(),
        'instructions': 'Edit each zh value, keep category names and entry keys intact. Restart the application after saving UTF-8 JSON.',
    },
    'categories': {},
}
cache = {}
translated_count = 0
for category, rows in catalog.items():
    result['categories'][category] = {}
    if category == 'weapons':
        rows = [row for row in rows if row.get('heroWeapon')]
    for row in rows:
        key = row['key']
        label_key = resource_labels[key] if category == 'resources' else key
        label = labels.get(label_key)
        name_source = 'game-english' if label else 'split-identifier'
        if not label:
            label = re.sub(r'([a-z0-9])([A-Z])', r'\1 \2', re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1 \2', key)).replace('_', ' ')
        label = re.sub(r'\{[^}]*\}', '', label).strip()
        if not label:
            raise ValueError(f'Empty English name: {category}/{key}')
        if label not in cache:
            cache[label] = translator.translate(label).strip()
        translated = cache[label]
        if not translated:
            raise ValueError(f'Empty translation: {category}/{key}')
        result['categories'][category][key] = {'en': label, 'zh': translated, 'source': name_source}
        translated_count += 1
        if translated_count % 25 == 0:
            print(f'Translated {translated_count} entries', flush=True)
    print(f'Completed {category}: {len(rows)}', flush=True)

args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'Wrote {translated_count} translated entries to {args.output}', flush=True)
