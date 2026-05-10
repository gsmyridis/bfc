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
