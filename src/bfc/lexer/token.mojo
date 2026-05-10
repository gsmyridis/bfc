from std.collections.string import CodepointsIter

from span import Span

# ===-----------------------------------------------------------------------===#
# TokenKind
# ===-----------------------------------------------------------------------===#

@fieldwise_init
struct TokenKind(
    Equatable,
    ImplicitlyCopyable,
    RegisterPassable,
    Writable,
):
    var _value: Int8

    comptime Plus = TokenKind(0)
    comptime Minus = TokenKind(1)
    comptime LessThan = TokenKind(2)
    comptime GreaterThan = TokenKind(3)
    comptime Comma = TokenKind(4)
    comptime Dot = TokenKind(5)
    comptime OpenBracket = TokenKind(6)
    comptime CloseBracket = TokenKind(7)
    comptime Eof = TokenKind(8)
    comptime Other = TokenKind(9)


    def __init__(out self, code: Codepoint):
        # TODO: Turn this to switch / match when feature becomses
        # available.
        if code == Codepoint.ord("+"):
            return TokenKind.Plus
        elif code == Codepoint.ord("-"):
            return TokenKind.Minus
        elif code == Codepoint.ord("<"):
            return TokenKind.LessThan
        elif code == Codepoint.ord(">"):
            return TokenKind.GreaterThan
        elif code == Codepoint.ord(","):
            return TokenKind.Comma
        elif code == Codepoint.ord("."):
            return TokenKind.Dot
        elif code == Codepoint.ord("["):
            return TokenKind.OpenBracket
        elif code == Codepoint.ord("]"):
            return TokenKind.CloseBracket
        else:
            return TokenKind.Other


    def is_bracket(self) -> Bool:
        """Returns true if the token kind is open or close bracket."""
        return (
            self == TokenKind.OpenBracket or 
            self == TokenKind.CloseBracket
        )


    def write_to(self, mut writer: Some[Writer]):
        # TODO: Turn this to switch / match when feature becomses
        # available.
        if self == TokenKind.Plus:
            writer.write("TokenKind.Plus")
        elif self == TokenKind.Minus:
            writer.write("TokenKind.Minus")
        elif self == TokenKind.GreaterThan:
            writer.write("TokenKind.GreaterThan")
        elif self == TokenKind.LessThan:
            writer.write("TokenKind.LessThan")
        elif self == TokenKind.Comma:
            writer.write("TokenKind.Comma")
        elif self == TokenKind.Dot:
            writer.write("TokenKind.Dot")
        elif self == TokenKind.OpenBracket:
            writer.write("TokenKind.OpenBracket")
        elif self == TokenKind.CloseBracket:
            writer.write("TokenKind.CloseBracket")
        else:
            debug_assert(self == TokenKind.Other)
            writer.write("TokenKind.Other")


    def write_repr_to(self, mut writer: Some[Writer]):
        self.write_to(writer)


# ===-----------------------------------------------------------------------===#
# Token
# ===-----------------------------------------------------------------------===#


@fieldwise_init
struct Token(ImplicitlyCopyable, Writable):
    var kind: TokenKind
    var span: Span

    @staticmethod
    def dummy() -> Token:
        return Token(TokenKind.Other, -1)


# ===-----------------------------------------------------------------------===#
# TokenIter
# ===-----------------------------------------------------------------------===#


struct TokenIter[origin: Origin[mut=False]](
    IterableOwned,
    Iterator,
    Movable,
):
    comptime Element = Token

    comptime IteratorOwnedType: Iterator = Self

    var _index: Int
    """Index of next token."""

    var _codes: CodepointsIter[mut=False, origin=Self.origin]
    """Iterator over the code-points of the source file string."""

    def __init__(
        out self, codes: CodepointsIter[mut=False, origin=Self.origin]
    ):
        self._index = 0
        self._codes = codes

    def __iter__(var self) -> Self.IteratorOwnedType:
        return self^

    def __next__(mut self) raises StopIteration -> Self.Element:
        self._index += 1
        var next_code = next(self._codes)
        var token_kind = TokenKind(next_code)
        return Token(token_kind, self._index - 1)


def tokenize(src: String) -> TokenIter[origin=origin_of(src)]:
    return TokenIter(src.codepoints())
