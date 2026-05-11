from std.os import abort

from ast import ASTOpKind, ASTOp, ASTree, Block
from ir import IROpKind, IROp, IRStream


struct Memory(Movable):
    var _memory: List[UInt8]
    """Memory as array of bytes."""

    var head: Int
    """Index where the head of the memory points to."""

    def __init__(out self, size: Int):
        self._memory = List[UInt8](length=size, fill=0)
        self.head = 0

    def write(mut self, value: UInt8):
        """Writes the byte value at head position."""
        self._memory[self.head] = value

    def read(self) -> UInt8:
        """Reads the byte at head position."""
        return self._memory[self.head]

    def head_forward(mut self, n: Int):
        """Moves the head position forward."""
        self.head += n

    def head_backwards(mut self, n: Int):
        """Moves the head position backwards."""
        self.head -= n


struct Interpreter:
    var memory: Memory
    var ip: Int

    def __init__(out self, var mem: Memory):
        self.memory = mem^
        self.ip = 0

    def _add(mut self, value: UInt8):
        """Adds value to the current byte."""
        self.memory.write(self.memory.read() + value)

    def _output(self):
        """Prints the current byte as ASCII character."""
        print(Codepoint(self.memory.read()), end="")

    def interpret_ast(mut self, ast: ASTree) raises:
        """Interprets the AST walking the tree."""
        for ast_node in ast:
            var node = ast_node[].copy()

            if node.value.isa[ASTOp]():
                self._interpret_ast_op(node.value[ASTOp])
            else:
                var block = node.value[Block].copy()
                while self.memory.read() != 0:
                    self.interpret_ast(block.astree)

    def _interpret_ast_op(mut self, op: ASTOp) raises:
        if op.kind == ASTOpKind.Increment:
            self._add(1)
        elif op.kind == ASTOpKind.Decrement:
            self._add(-1)
        elif op.kind == ASTOpKind.Right:
            self.memory.head_forward(1)
        elif op.kind == ASTOpKind.Left:
            self.memory.head_backwards(1)
        elif op.kind == ASTOpKind.Output:
            self._output()
        elif op.kind == ASTOpKind.Input:
            raise Error("input is not implemented")
        else:
            assert (
                op.kind == ASTOpKind.JumpIfZero or
                op.kind == ASTOpKind.JumpIfNonZero
            )

    def interpret_ir(mut self, stream: IRStream) raises:
        """
        Interprets the IR stream manipulating the instruction 
        pointer.
        """
        self.ip = 0
        while self.ip < len(stream):
            var op = stream[self.ip]

            if op.kind == IROpKind.JumpIfZero:
                if self.memory.read() == 0:
                    self.ip = op.operand
                else:
                    self.ip += 1
            elif op.kind == IROpKind.JumpIfNonZero:
                if self.memory.read() != 0:
                    self.ip = op.operand
                else:
                    self.ip += 1
            else:
                self._interpret_ir_op(op)
                self.ip += 1

    def _interpret_ir_op(mut self, op: IROp) raises:
        if op.kind == IROpKind.Increment:
            assert op.operand < 255
            self._add(UInt8(op.operand))
        elif op.kind == IROpKind.Decrement:
            self._add(-UInt8(op.operand))
        elif op.kind == IROpKind.Right:
            self.memory.head_forward(op.operand)
        elif op.kind == IROpKind.Left:
            self.memory.head_backwards(op.operand)
        elif op.kind == IROpKind.Output:
            for _ in range(op.operand):
                self._output()
        elif op.kind == IROpKind.Input:
            raise Error("input is not implemented")
        else:
            abort(t"invalid non-linear `IROpKind`: {op.kind}")
