from std.os import abort

from lexer import TokenKind, Token, TokenTree, TokenStream, Delimited
from ast import Op, ASTNode, ASTree, Block


@fieldwise_init
struct Parser:
    def parse(self, token_stream: TokenStream) -> ASTree:
        var ast = ASTree()

        for tt in token_stream:
            # TODO: Avoid copy and extra allocation
            var ast_node = self.parse_token_tree(tt[].copy())
            var ast_node_ptr = ASTNode.boxed(ast_node^)
            ast.append(ast_node_ptr)

        return ast^

    def parse_token_tree(self, var tt: TokenTree) -> ASTNode:
        if tt.value.isa[Token]():
            return ASTNode(self.parse_token(tt.value[Token]))
        elif tt.value.isa[Delimited]():
            var body = self.parse(tt.value[Delimited].tokenstream)
            var block = Block(
                tt.value[Delimited].span_open,
                tt.value[Delimited].span_close,
                body^,
            )
            return ASTNode(block^)

        abort("`TokenTree` is either `Token` or `Delimited`")

    def parse_token(self, token: Token) -> Op:
        if token.kind == TokenKind.Plus:
            return Op.Increment
        elif token.kind == TokenKind.Minus:
            return Op.Decrement
        elif token.kind == TokenKind.LessThan:
            return Op.Left
        elif token.kind == TokenKind.GreaterThan:
            return Op.Right
        elif token.kind == TokenKind.Comma:
            return Op.Input
        elif token.kind == TokenKind.Dot:
            return Op.Output

        abort(t"invalid `TokenKind`: {token.kind}")
