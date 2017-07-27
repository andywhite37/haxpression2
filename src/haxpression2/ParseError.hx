package haxpression2;

import haxe.PosInfos;
import haxe.CallStack;

import thx.Error;

import Parsihax;

class ParseError extends Error {
  public var input(default, null) : String;
  public var index(default, null) : Int;
  public var furthest(default, null) : Int;
  public var expected(default, null) : Array<String>;

  public function new(input : String, index: Int, furthest: Int, expected: Array<String>, message: String, ?stack: Array<StackItem>, ?pos: PosInfos) {
    super(message, stack, pos);
    this.index = index;
    this.furthest = furthest;
    this.expected = expected;
  }

  public static function fromParseResult<T>(input : String, parseResult : Result<T>) : ParseError {
    var formatted = Parsihax.formatError(parseResult, input);
    return new ParseError(
      input,
      parseResult.index,
      parseResult.furthest,
      parseResult.expected,
      'Failed to parse expression: $input (index: ${parseResult.index}, furthest: ${parseResult.furthest}): $formatted'
    );
  }

  public override function toString() : String {
    //return '$message (expected: ${expected.join("\n")})';
    return message;
  }
}
