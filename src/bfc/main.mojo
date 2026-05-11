from std.sys import exit
from lexer.token import tokenize
from lexer import Lexer
from parser import Parser
from ir import lower_ast
from interp import Interpreter, Memory


def read_to_string(path: String) -> String:
    """Reads bytes from file."""
    try:
        with open(path, "r") as file:
            return file.read()
    except:
        print(t"ERROR: failed to read file {path}")
        exit(1)
        return String()  # Workaround


def main() raises:
    path = "examples/hello_world.bf"
    var string = read_to_string(path)

    var lexer = Lexer[origin=origin_of(string)](string)
    var ts = lexer.lex_token_trees()
    var ast = Parser().parse(ts)
    var ir = lower_ast(ast)

    var interp = Interpreter(Memory(256))
    interp.interpret_ir(ir)
