from lexer import Lexer
from token import Token


struct Parser[TokenIter: Iterator where TokenIter.Element is Token]:
    var tokens: Self.TokenIter

    def __init__(out self, var tokens: Self.TokenIter):
        self.tokens = tokens^

    def next_token(mut self) raises -> Token:
        return self.tokens.__next__()


def main() raises:
    var source = String("+-")
    var parser = Parser(Lexer(source.codepoints()))
    print(parser.next_token())
