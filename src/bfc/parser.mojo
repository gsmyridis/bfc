from token import Token, TokenIter
from ast import Op
from std.iter import StopIteration


# struct Parser[origin: Origin[mut=False]](
#     IterableOwned,
#     Iterator,
# ):
#     comptime Element = Op
#
#     comptime IteratorOwnedType: Iterator = Self
#
#     var token_iter: TokenIter[origin=Self.origin]
#
#     def __init__(out self, var token_iter: TokenIter[origin=Self.origin]):
#         self.token_iter = token_iter^
#
#     def __iter__(var self) -> Self.IteratorOwnedType:
#         return self^
#
#     def __next__(mut self) raises StopIteration -> Self.Element:
#         while True:
#             var token = next(self.token_iter)
#             if token == Token.Plus:
#                 return Op.Increment
#             elif token == Token.Minus:
#                 return Op.Decrement
#             elif token == Token.LessThan:
#                 return Op.Left
#             elif token == Token.GreaterThan:
#                 return Op.Right
#             elif token == Token.Comma:
#                 return Op.Input
#             elif token == Token.Dot:
#                 return Op.Output
#             elif token == Token.OpenBracket:
#                 return Op.JumpIfZero
#             elif token == Token.CloseBracket:
#                 return Op.JumpIfNonZero
#
#
# def parse[
#     origin: Origin[mut=False]
# ](var token_iter: TokenIter[origin=origin],) -> Parser[origin=origin]:
#     return Parser(token_iter^)
