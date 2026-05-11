from std.utils import Variant
from span import Span
from ast import Op, ASTree, Block


# ===-----------------------------------------------------------------------===#
# Intermediate Representation Operation
# ===-----------------------------------------------------------------------===#


struct IROp(Copyable, Writable):
    var op: Op
    var count: Int

    def __init__(out self, op: Op, count: Int):
        self.op = op
        self.count = count

    def write_to(self, mut writer: Some[Writer]):
        writer.write(t"IROp({self.op}, {self.count})")

    def write_repr_to(self, mut writer: Some[Writer]):
        self.write_to(writer)


# ===-----------------------------------------------------------------------===#
# Intermediate Representation Node
# ===-----------------------------------------------------------------------===#


struct IRNode(Copyable, Writable):
    comptime Ptr = UnsafePointer[Self, MutExternalOrigin]

    var value: Variant[IROp, IRBlock]

    def __init__(out self, var op: IROp):
        self.value = op^

    def __init__(out self, var block: IRBlock):
        self.value = block^

    @staticmethod
    def boxed(var node: IRNode) -> IRNode.Ptr:
        var ptr = alloc[Self](1)
        ptr.init_pointee_move(node^)
        return ptr

    def write_to(self, mut writer: Some[Writer]):
        if self.value.isa[IROp]():
            writer.write(t"IRNode({self.value[IROp]})")
        else:
            writer.write(t"IRNode({self.value[IRBlock]})")

    def write_repr_to(self, mut writer: Some[Writer]):
        self.write_to(writer)


# ===-----------------------------------------------------------------------===#
# Intermediate Representation Block
# ===-----------------------------------------------------------------------===#


struct IRBlock(Copyable, Writable):
    var span_open: Span
    var span_close: Span
    var body: IR

    def __init__(out self, open: Span, close: Span, var body: IR):
        self.span_open = open
        self.span_close = close
        self.body = body^

    def write_to(self, mut writer: Some[Writer]):
        writer.write(
            t"IRBlock(span_open={self.span_open}, span_close={self.span_close},"
            t" body=["
        )
        for i in range(len(self.body)):
            if i != 0:
                writer.write(", ")
            var child = self.body[i]
            writer.write(child[])
        writer.write("])")

    def write_repr_to(self, mut writer: Some[Writer]):
        self.write_to(writer)


# ===-----------------------------------------------------------------------===#
# Intermediate Representation
# ===-----------------------------------------------------------------------===#

comptime IR = List[IRNode.Ptr]


@fieldwise_init
struct IRBuilder:
    def lower_ast(self, ast: ASTree) -> IR:
        var ir = IR()
        var has_pending = False
        var pending_op = Op.Increment
        var pending_count = 0

        for ast_node in ast:
            var node = ast_node[].copy()

            if node.value.isa[Op]():
                var op = node.value[Op]
                if self.can_batch(op):
                    if has_pending:
                        if pending_op == op:
                            pending_count += 1
                        else:
                            ir.append(self.box_op(pending_op, pending_count))
                            pending_op = op
                            pending_count = 1
                    else:
                        pending_op = op
                        pending_count = 1
                        has_pending = True
                else:
                    if has_pending:
                        ir.append(self.box_op(pending_op, pending_count))
                        has_pending = False
                    ir.append(self.box_op(op, 1))
            else:
                if has_pending:
                    ir.append(self.box_op(pending_op, pending_count))
                    has_pending = False

                var block = node.value[Block].copy()
                var body = self.lower_ast(block.astree)
                var ir_block = IRBlock(block.span_open, block.span_close, body^)
                ir.append(IRNode.boxed(IRNode(ir_block^)))

        if has_pending:
            ir.append(self.box_op(pending_op, pending_count))

        return ir^

    def can_batch(self, op: Op) -> Bool:
        return (
            op == Op.Increment
            or op == Op.Decrement
            or op == Op.Left
            or op == Op.Right
            or op == Op.Input
            or op == Op.Output
        )

    def box_op(self, op: Op, count: Int) -> IRNode.Ptr:
        return IRNode.boxed(IRNode(IROp(op, count)))


def lower_ast(ast: ASTree) -> IR:
    return IRBuilder().lower_ast(ast)
