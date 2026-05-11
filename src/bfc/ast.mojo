from std.utils import Variant
from span import Span

# ===-----------------------------------------------------------------------===#
# AST Operation Kind
# ===-----------------------------------------------------------------------===#


@fieldwise_init
struct ASTOpKind(Equatable, ImplicitlyCopyable, RegisterPassable, Writable):
    var _id: Int8

    comptime Increment = ASTOpKind(0)
    comptime Decrement = ASTOpKind(1)
    comptime Left = ASTOpKind(2)
    comptime Right = ASTOpKind(3)
    comptime Input = ASTOpKind(4)
    comptime Output = ASTOpKind(5)
    comptime JumpIfZero = ASTOpKind(6)
    comptime JumpIfNonZero = ASTOpKind(7)

    def is_jump(self) -> Bool:
        return (
            self == Self.JumpIfZero or self == Self.JumpIfNonZero
        )

    def write_to(self, mut writer: Some[Writer]):
        if self == ASTOpKind.Increment:
            writer.write("ASTOpKind.Increment")
        elif self == ASTOpKind.Decrement:
            writer.write("ASTOpKind.Decrement")
        elif self == ASTOpKind.Left:
            writer.write("ASTOpKind.Left")
        elif self == ASTOpKind.Right:
            writer.write("ASTOpKind.Right")
        elif self == ASTOpKind.Input:
            writer.write("ASTOpKind.Input")
        elif self == ASTOpKind.Output:
            writer.write("ASTOpKind.Output")
        elif self == ASTOpKind.JumpIfZero:
            writer.write("ASTOpKind.JumpIfZero")
        else:
            debug_assert(self == ASTOpKind.JumpIfNonZero)
            writer.write("ASTOpKind.JumpIfNonZero")


# ===-----------------------------------------------------------------------===#
# AST Operation
# ===-----------------------------------------------------------------------===#


@fieldwise_init
struct ASTOp(ImplicitlyCopyable, Writable):
    var kind: ASTOpKind
    var operand: Optional[Int]

    def __init__(out self, kind: ASTOpKind):
        self.kind = kind
        self.operand = None

    def __init__(out self, kind: ASTOpKind, operand: Int):
        self.kind = kind
        self.operand = operand

    def write_to(self, mut writer: Some[Writer]):
        if self.operand:
            writer.write(t"ASTOp({self.kind}, operand={self.operand})")
        else:
            writer.write(t"ASTOp({self.kind})")


# ===-----------------------------------------------------------------------===#
# Abstract Syntax Tree Node
# ===-----------------------------------------------------------------------===#


# TODO: Ideally, avoid allocations
struct ASTNode(Copyable, Writable):
    comptime Ptr = UnsafePointer[Self, MutExternalOrigin]

    var value: Variant[ASTOp, Block]

    def __init__(out self, op: ASTOp):
        self.value = op

    def __init__(out self, var block: Block):
        self.value = block^

    @staticmethod
    def boxed(var node: ASTNode) -> ASTNode.Ptr:
        var ptr = alloc[Self](1)
        ptr.init_pointee_move(node^)
        return ptr

    def write_to(self, mut writer: Some[Writer]):
        if self.value.isa[ASTOp]():
            writer.write(t"ASTNode({self.value[ASTOp]})")
        else:
            writer.write(t"ASTNode({self.value[Block]})")


# ===-----------------------------------------------------------------------===#
# Block
# ===-----------------------------------------------------------------------===#


struct Block(Copyable, Writable):
    var span_open: Span
    var span_close: Span
    var astree: ASTree

    def __init__(out self, open: Span, close: Span, var tree: ASTree):
        self.span_open = open
        self.span_close = close
        self.astree = tree^

    def write_to(self, mut writer: Some[Writer]):
        writer.write(
            t"Block(span_open={self.span_open}, span_close={self.span_close},"
            t" body=["
        )
        for i in range(len(self.astree)):
            if i != 0:
                writer.write(", ")
            var child = self.astree[i]
            writer.write(child[])
        writer.write("])")


# ===-----------------------------------------------------------------------===#
# Abstract Syntax Tree
# ===-----------------------------------------------------------------------===#

comptime ASTree = List[ASTNode.Ptr]
