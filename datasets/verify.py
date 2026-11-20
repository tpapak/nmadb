#!/usr/bin/env python3
"""Verify dataset mappings, Git commit URLs, workbook containers, and SHA-256."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import zipfile


def main():
    root = Path(__file__).resolve().parent.parent
    document = json.loads((root / 'datasets/manifest.json').read_text())
    revision = document['file_revision']
    assert re.fullmatch(r'[0-9a-f]{40}', revision), 'Expected a full Git commit SHA'
    rows = document['files']
    assert document['record_count'] == len(rows)
    assert len({(row['record_id'], row['field']) for row in rows}) == len(rows)
    assert document['unique_file_count'] == len({row['sha256'] for row in rows})
    assert all(isinstance(row['record_id'], str) and row['field'] == 'dataset' for row in rows)
    total = 0
    for row in rows:
        relative = f'datasets/files/{row["sha256"]}.xlsx'
        assert row['path'] == relative
        assert row['file_url'] == f'https://raw.githubusercontent.com/{document["repository"]}/{revision}/{relative}'
        local = root / relative
        content = local.read_bytes()
        assert len(content) == row['size']
        assert hashlib.sha256(content).hexdigest() == row['sha256']
        committed = subprocess.check_output(['git', 'show', f'{revision}:{relative}'], cwd=root)
        assert content == committed, 'Pinned Git revision contains different bytes'
        with zipfile.ZipFile(local) as workbook:
            assert workbook.testzip() is None
            assert 'xl/workbook.xml' in workbook.namelist()
        total += len(content)
    expected_paths = {root / row['path'] for row in rows}
    assert set((root / 'datasets/files').iterdir()) == expected_paths, 'Unexpected extra files'
    print(f'Verified {len(rows)} record mappings and {len(expected_paths)} Excel files ({total:,} bytes).')


if __name__ == '__main__':
    main()
