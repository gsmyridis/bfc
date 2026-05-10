from std.utils import Variant
from .token import TokenKind


# ===-----------------------------------------------------------------------===#
# TokenTree
# ===-----------------------------------------------------------------------===#


@fieldwise_init
struct TokenTree(Copyable, Writable):
    comptime Ptr = UnsafePointer[Self, MutExternalOrigin]

    var token_tree: Variant[Token, Delimited]

    def __init__(out self, token: Token):
        self.token_tree = Variant[Token, Delimited](token)

    def __init__(out self, var delimited: Delimited):
        self.token_tree = Variant[Token, Delimited](delimited^)

    @staticmethod
    def new(var tt: TokenTree) -> Self.Ptr:
        var ptr = alloc[Self](1)
        ptr.init_pointee_move(tt^)
        return ptr

    def write_to(self, mut writer: Some[Writer]):
        if self.token_tree.isa[Token]():
            writer.write(t"TokenTree({self.token_tree[Token]})")
        else:
            writer.write(t"TokenTree({self.token_tree[Delimited]})")

    def write_repr_to(self, mut writer: Some[Writer]):
        self.write_to(writer)


# ===-----------------------------------------------------------------------===#
# Delimited
# ===-----------------------------------------------------------------------===#


@fieldwise_init
struct Delimited(Copyable, Writable):
    var span_open: Int
    var span_close: Int
    var tokenstream: List[TokenTree.Ptr]

    def write_to(self, mut writer: Some[Writer]):
        writer.write(
            t"Delimited(span_open={self.span_open},"
            t" span_close={self.span_close}, children=["
        )
        for i in range(len(self.tokenstream)):
            if i != 0:
                writer.write(", ")
            var child = self.tokenstream[i]
            writer.write(child[])
        writer.write("])")

    def write_repr_to(self, mut writer: Some[Writer]):
        self.write_to(writer)


# ===-----------------------------------------------------------------------===#
# TokenStream
# ===-----------------------------------------------------------------------===#


comptime TokenStream = List[TokenTree.Ptr]
