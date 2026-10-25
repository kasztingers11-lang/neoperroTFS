"""Run production Luau control flow under Lua 5.4 with explicit Roblox mocks.

Requires Python 3.12 and lupa (pip install lupa). --deps can point at an existing
dependency directory. This strips only ': any' annotations; it does not rewrite logic.
"""
import argparse
import re
import sys
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--deps', help='Optional existing Python dependency directory')
args = parser.parse_args()
if args.deps:
    sys.path.insert(0, args.deps)
from lupa.lua54 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)


def load_source(name):
    source = (root / 'src' / f'{name}.luau').read_text(encoding='utf-8')
    return lua.execute(re.sub(r':\s*any\b', '', source))


lua.globals().LoadSource = load_source
lua.execute((root / 'tests' / 'automation.test.lua').read_text(encoding='utf-8'))
