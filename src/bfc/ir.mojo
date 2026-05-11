from ast import ASTOpKind, ASTOp, ASTree, Block


# ===-----------------------------------------------------------------------===#
# Intermediate Representation Operation Kind
# ===-----------------------------------------------------------------------===#


@fieldwise_init
struct IROpKind(Equatable, ImplicitlyCopyable, RegisterPassable, Writable):
    var _id: Int8

    comptime Increment = IROpKind(0)
    comptime Decrement = IROpKind(1)
    comptime Left = IROpKind(2)
    comptime Right = IROpKind(3)
    comptime Input = IROpKind(4)
    comptime Output = IROpKind(5)
    comptime JumpIfZero = IROpKind(6)
    comptime JumpIfNonZero = IROpKind(7)

    def write_to(self, mut writer: Some[Writer]):
        if self == IROpKind.Increment:
            writer.write("IROpKind.Increment")
        elif self == IROpKind.Decrement:
            writer.write("IROpKind.Decrement")
        elif self == IROpKind.Left:
            writer.write("IROpKind.Left")
        elif self == IROpKind.Right:
            writer.write("IROpKind.Right")
        elif self == IROpKind.Input:
            writer.write("IROpKind.Input")
        elif self == IROpKind.Output:
            writer.write("IROpKind.Output")
        elif self == IROpKind.JumpIfZero:
            writer.write("IROpKind.JumpIfZero")
        else:
            debug_assert(self == IROpKind.JumpIfNonZero)
            writer.write("IROpKind.JumpIfNonZero")


# ===-----------------------------------------------------------------------===#
# Intermediate Representation Operation
# ===-----------------------------------------------------------------------===#

@fieldwise_init
struct IROp(ImplicitlyCopyable, Writable):
    var kind: IROpKind
    var operand: Int

    def write_to(self, mut writer: Some[Writer]):
        writer.write(t"IROp({self.kind}, operand={self.operand})")

comptime IRStream = List[IROp]


@fieldwise_init
struct IRBuilder:
    def lower_ast(self, ast: ASTree) raises -> IRStream:
        var ir = IRStream()
        self.lower_ast_into(ir, ast)
        return ir^

    def lower_ast_into(self, mut ir: IRStream, ast: ASTree) raises:
        var has_pending = False
        var pending_kind = IROpKind.Increment
        var pending_count = 0

        for ast_node in ast:
            var node = ast_node[].copy()

            if node.value.isa[ASTOp]():
                var ast_op = node.value[ASTOp]
                if self.is_jump(ast_op.kind):
                    continue

                var kind = self.to_ir_kind(ast_op.kind)
                if self.can_batch(kind):
                    if has_pending:
                        if pending_kind == kind:
                            pending_count += 1
                        else:
                            self.flush_pending(ir, pending_kind, pending_count)
                            pending_kind = kind
                            pending_count = 1
                    else:
                        pending_kind = kind
                        pending_count = 1
                        has_pending = True
                else:
                    if has_pending:
                        self.flush_pending(ir, pending_kind, pending_count)
                        has_pending = False
                    ir.append(IROp(kind, self.operand_or_one(ast_op)))
            else:
                if has_pending:
                    self.flush_pending(ir, pending_kind, pending_count)
                    has_pending = False

                var block = node.value[Block].copy()
                var open_index = len(ir)
                ir.append(IROp(IROpKind.JumpIfZero, 0))
                self.lower_ast_into(ir, block.astree)
                var close_index = len(ir)
                ir.append(IROp(IROpKind.JumpIfNonZero, open_index))
                ir[open_index].operand = close_index

        if has_pending:
            self.flush_pending(ir, pending_kind, pending_count)

    def flush_pending(
        self, mut ir: IRStream, kind: IROpKind, count: Int
    ):
        ir.append(IROp(kind, count))

    def can_batch(self, kind: IROpKind) -> Bool:
        return (
            kind == IROpKind.Increment
            or kind == IROpKind.Decrement
            or kind == IROpKind.Left
            or kind == IROpKind.Right
            or kind == IROpKind.Input
            or kind == IROpKind.Output
        )

    def is_jump(self, kind: ASTOpKind) -> Bool:
        return (
            kind == ASTOpKind.JumpIfZero
            or kind == ASTOpKind.JumpIfNonZero
        )

    def operand_or_one(self, op: ASTOp) raises -> Int:
        if op.operand == None:
            return 1
        return op.operand[]

    def to_ir_kind(self, kind: ASTOpKind) -> IROpKind:
        if kind == ASTOpKind.Increment:
            return IROpKind.Increment
        elif kind == ASTOpKind.Decrement:
            return IROpKind.Decrement
        elif kind == ASTOpKind.Left:
            return IROpKind.Left
        elif kind == ASTOpKind.Right:
            return IROpKind.Right
        elif kind == ASTOpKind.Input:
            return IROpKind.Input
        elif kind == ASTOpKind.Output:
            return IROpKind.Output
        elif kind == ASTOpKind.JumpIfZero:
            return IROpKind.JumpIfZero

        debug_assert(kind == ASTOpKind.JumpIfNonZero)
        return IROpKind.JumpIfNonZero


def lower_ast(ast: ASTree) raises -> IRStream:
    return IRBuilder().lower_ast(ast)
