struct Span(ImplicitlyCopyable, RegisterPassable, Writable):
    var value: Int

    @implicit
    def __init__(out self, value: Int):
        self.value = value

    def write_to(self, mut writer: Some[Writer]):
        writer.write(t"Span({self.value})")
