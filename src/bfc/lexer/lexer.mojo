from .token import Token, TokenIter, TokenKind
from .tokentree import TokenTree, Delimited, TokenStream


struct Lexer[origin: Origin[mut=False]]:
    var tokens: TokenIter[origin=Self.origin]
    var token: Token

    def __init__(out self, src: StringSlice[origin=Self.origin]):
        self.tokens = TokenIter(src.codepoints())
        self.token = Token.dummy()

    def bump(mut self) raises StopIteration -> Token:
        var next_token = next(self.tokens)
        self.token = next_token
        return next_token^

    def lex_token_trees(mut self) raises -> TokenStream:
        return self._lex_token_trees_inner(False)

    def _lex_token_trees_inner(mut self, is_delimited: Bool) raises -> TokenStream:
        var buf = TokenStream()

        while True:
            # Try to get the next token.
            var this_tok: Token
            try:
                this_tok = self.bump()
            except StopIteration:
                if is_delimited:
                    # FIXME: Diagnostics
                    raise Error("unclosed bracket")
                return buf^

            # If there is an open bracked, lex the nexted token subtree
            if this_tok.kind == TokenKind.OpenBracket:
                var nested = self._lex_token_trees_inner(True)
                var tt = TokenTree.boxed(
                    TokenTree(
                        Delimited(
                            this_tok.span.value,
                            self.token.span.value,
                            nested^,
                        )
                    )
                )
                buf.append(tt)

            # If there is a close bracket, return the currently lexed
            # token subtree.
            elif this_tok.kind == TokenKind.CloseBracket:
                if is_delimited:
                    return buf^

                # FIXME: Diagnostics
                raise Error("unexpected close bracket")

            # Else return a single token token-tree, skipping the 'comment'
            # tokens
            elif this_tok.kind != TokenKind.Other:
                buf.append(TokenTree.boxed(TokenTree(this_tok)))
