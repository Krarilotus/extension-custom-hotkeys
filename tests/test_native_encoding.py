"""Exercise production conversion through real Windows APIs, without a game."""
import sys
from pathlib import Path

import pytest

pytestmark = pytest.mark.skipif(sys.platform != 'win32', reason='Windows text API')


@pytest.fixture
def encoding():
    from lupa.luajit21 import LuaRuntime
    lua = LuaRuntime(encoding=None, unpack_returned_tuples=True)
    lua.globals().root = Path(__file__).resolve().parents[1].as_posix().encode()
    lua.execute(b"package.path=root..'/?.lua;'..package.path")
    return lua.eval(b"(require('code/native/encoding'))")


@pytest.mark.parametrize('text,codepage,codec', [
    ('Öffnen', 1252, 'cp1252'), ('Pozycja', 1250, 'cp1250'),
    ('Горячие клавиши', 1251, 'cp1251'), ('Gyorsbillentyűk', 1250, 'cp1250'),
    ('Özel Kısayollar', 1254, 'cp1254'), ('自定义快捷键', 936, 'gbk'),
    ('میانبرهای سفارشی', 1256, 'cp1256'), ('中文', 65001, 'utf-8'),
    ('中文', 54936, 'gb18030'),
])
def test_loaded_game_codepage_roundtrip(encoding, text, codepage, codec):
    normalized = text.replace('\u06cc', '\u064a') if codepage == 1256 else text
    encoded = encoding[b'display'](text.encode(), codepage)
    assert encoded == normalized.encode(codec)
    assert encoding[b'read'](encoded, codepage) == normalized.encode()


def test_invalid_and_unrepresentable_text_is_rejected_without_best_fit(encoding):
    for text, codepage in [(b'\xc0\xaf', 1252), ('中文'.encode(), 1252), (b'valid', 99999)]:
        assert encoding[b'display'](text, codepage) == (None, b'text.encoding')
