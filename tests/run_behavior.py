




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


def load_ui_input(env):
    
    
    source = (root / 'src' / 'Library.luau').read_text(encoding='utf-8')
    ranges = [
        ('    function Library.HandleMenuInput(Input)', '    Library:SetMenuKey(Enum.KeyCode.RightShift)'),
        ('                        function Keybind:SetStateType(State)',
         '                        Utility.AddConnection("InputBegan", function(Input) Keybind:HandleShortcut(Input) end)'),
        ('                        function Keybind:Set(Key, Mode)', '                        table.insert(Library.Bindings, Keybind)'),
    ]
    methods = []
    for start, end in ranges:
        first = source.index(start)
        methods.append(source[first:source.index(end, first)])
    lua.eval("function(s, e) return assert(load(s, 'production UI input', 't', e))() end")('\n'.join(methods), env)


def load_ui_visibility(env):
    source = (root / 'src' / 'Library.luau').read_text(encoding='utf-8')
    first = source.index('    function Library:ChangeVisible(State)')
    method = source[first:source.index('    function Library:UpdateTheme(Config)', first)]
    lua.eval("function(s, e) return assert(load(s, 'production UI visibility', 't', e))() end")(method, env)


lua.globals().LoadUIVisibility = load_ui_visibility
lua.globals().LoadUIInput = load_ui_input
lua.execute((root / 'tests' / 'automation.test.lua').read_text(encoding='utf-8'))
