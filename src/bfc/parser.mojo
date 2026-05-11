from std.os import abort

from lexer import TokenKind, Token, TokenTree, TokenStream, Delimited
from ast import ASTOpKind, ASTOp, ASTNode, ASTree, Block


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
            var delimited = tt.value[Delimited].copy()
            var nested = self.parse(delimited.tokenstream)
            var body = ASTree()
            body.append(
                ASTNode.boxed(
                    ASTNode(ASTOp(ASTOpKind.JumpIfZero, delimited.span_close))
                )
            )
            for child in nested:
                body.append(child)
            body.append(
                ASTNode.boxed(
                    ASTNode(ASTOp(ASTOpKind.JumpIfNonZero, delimited.span_open))
                )
            )
            var block = Block(
                delimited.span_open,
                delimited.span_close,
                body^,
            )
            return ASTNode(block^)

        abort("`TokenTree` is either `Token` or `Delimited`")

    def parse_token(self, token: Token) -> ASTOp:
        if token.kind == TokenKind.Plus:
            return ASTOp(ASTOpKind.Increment)
        elif token.kind == TokenKind.Minus:
            return ASTOp(ASTOpKind.Decrement)
        elif token.kind == TokenKind.LessThan:
            return ASTOp(ASTOpKind.Left)
        elif token.kind == TokenKind.GreaterThan:
            return ASTOp(ASTOpKind.Right)
        elif token.kind == TokenKind.Comma:
            return ASTOp(ASTOpKind.Input)
        elif token.kind == TokenKind.Dot:
            return ASTOp(ASTOpKind.Output)

        abort(t"invalid `TokenKind`: {token.kind}")
