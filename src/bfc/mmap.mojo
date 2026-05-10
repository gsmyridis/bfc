from std.ffi import c_int, c_long, c_size_t, external_call


comptime PAGE_SIZE = 4096
comptime PROT_READ = 0x1
comptime PROT_WRITE = 0x2
comptime MAP_PRIVATE = 0x2
comptime MAP_ANON = 0x1000  # macOS. Linux uses MAP_ANONYMOUS = 0x20.


def mmap_anonymous(
    length: Int,
) raises -> UnsafePointer[NoneType, MutExternalOrigin]:
    var result = external_call[
        "mmap",
        Optional[UnsafePointer[NoneType, MutExternalOrigin]],
        Optional[UnsafePointer[NoneType, MutExternalOrigin]],
        c_size_t,
        c_int,
        c_int,
        c_int,
        c_long,
    ](
        None,
        c_size_t(length),
        c_int(PROT_READ | PROT_WRITE),
        c_int(MAP_PRIVATE | MAP_ANON),
        c_int(-1),
        c_long(0),
    )

    if result == None:
        raise Error("mmap returned NULL")
    return result[]


def munmap(
    addr: UnsafePointer[NoneType, MutExternalOrigin], length: Int
) -> c_int:
    return external_call[
        "munmap",
        c_int,
        UnsafePointer[NoneType, MutExternalOrigin],
        c_size_t,
    ](addr, c_size_t(length))


def main() raises:
    var mapping = mmap_anonymous(PAGE_SIZE)
    var bytes = mapping.bitcast[UInt8]()

    for i in range(16):
        bytes[i] = UInt8(i * 3)

    var total = 0
    for i in range(16):
        total += Int(bytes[i])

    print("sum of bytes in mmap'd memory:", total)
    if total != 360:
        _ = munmap(mapping, PAGE_SIZE)
        raise Error("mmap memory readback check failed")

    var rc = munmap(mapping, PAGE_SIZE)
    if rc != 0:
        raise Error("munmap failed")

    print("mmap write/read/munmap check passed")
