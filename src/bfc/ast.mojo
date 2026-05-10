from std.utils import Variant
from span import Span

# ===-----------------------------------------------------------------------===#
# Operation
# ===-----------------------------------------------------------------------===#

@fieldwise_init
struct Op(Equatable, ImplicitlyCopyable, RegisterPassable, Writable):
    var _value: Int8

    comptime Increment = Op(0)
    comptime Decrement = Op(1)
    comptime Left = Op(2)
    comptime Right = Op(3)
    comptime Input = Op(4)
    comptime Output = Op(5)
    comptime JumpIfZero = Op(6)
    comptime JumpIfNonZero = Op(7)

    def write_to(self, mut writer: Some[Writer]):
        if self == Op.Increment:
            writer.write("Op.Increment")
        elif self == Op.Decrement:
            writer.write("Op.Decrement")
        elif self == Op.Left:
            writer.write("Op.Left")
        elif self == Op.Right:
            writer.write("Op.Right")
        elif self == Op.Input:
            writer.write("Op.Input")
        elif self == Op.Output:
            writer.write("Op.Output")
        elif self == Op.JumpIfZero:
            writer.write("Op.JumpIfZero")
        else:
            debug_assert(self == Op.JumpIfNonZero)
            writer.write("Op.JumpIfNonZero")

    def write_repr_to(self, mut writer: Some[Writer]):
        self.write_to(writer)


# ===-----------------------------------------------------------------------===#
# Abstract Syntax Tree Node
# ===-----------------------------------------------------------------------===#

# TODO: Ideally, avoid allocations
struct ASTNode(Copyable, Writable):
    comptime Ptr = UnsafePointer[Self, MutExternalOrigin]

    var value: Variant[Op, Block]

    def __init__(out self, op: Op):
        self.value = op

    def __init__(out self, var block: Block):
        self.value = block^

    @staticmethod
    def boxed(var node: ASTNode) -> ASTNode.Ptr:
        var ptr = alloc[Self](1)
        ptr.init_pointee_move(node^)
        return ptr

    def write_to(self, mut writer: Some[Writer]):
        if self.value.isa[Op]():
            writer.write(t"ASTNode({self.value[Op]})")
        else:
            writer.write(t"ASTNode({self.value[Block]})")

    def write_repr_to(self, mut writer: Some[Writer]):
        self.write_to(writer)


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
            t"Block(span_open={self.span_open}, span_close={self.span_close}, body=["
        )
        for i in range(len(self.astree)):
            if i != 0:
                writer.write(", ")
            var child = self.astree[i]
            writer.write(child[])
        writer.write("])")

    def write_repr_to(self, mut writer: Some[Writer]):
        self.write_to(writer)


# ===-----------------------------------------------------------------------===#
# Abstract Syntax Tree
# ===-----------------------------------------------------------------------===#

comptime ASTree = List[ASTNode.Ptr]
