package haxpression2;

import haxe.PosInfos;
import haxe.CallStack;

import thx.Error;

import Parsihax;

class ParseError<T> extends Error {
  public var input(default, null) : String;
  public var result(default, null) : Result<T>;

  function new(message : String, input : String, result: Result<T>, ?stack: Array<StackItem>, ?pos: PosInfos) {
    super(message, stack, pos);
    this.input = input;
    this.result = result;
  }

  public static function fromParseResult<T>(input : String, result : Result<T>) : ParseError<T> {
    var message = Parsihax.formatError(result, input);
    return new ParseError(
      message,
      input,
      result
    );
  }

  public override function toString() : String {
    //return '$message (expected: ${expected.join("\n")})';
    return message;
  }
}
