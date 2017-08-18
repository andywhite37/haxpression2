package haxpression2.parse;

import haxe.PosInfos;
import haxe.CallStack;
import haxe.ds.Option;

import thx.Error;
using thx.Options;

import Parsihax;

class ParseError<T> extends Error {
  public var input(default, null) : String;
  public var result(default, null) : Result<T>;
  public var field(default, null) : Option<String>;

  function new(message : String, input : String, result: Result<T>, field : Option<String>, ?stack: Array<StackItem>, ?pos: PosInfos) {
    super(message, stack, pos);
    this.input = input;
    this.result = result;
  }

  public static function forField<T>(error : ParseError<T>, field : String) : ParseError<T> {
    return new ParseError(error.message, error.input, error.result, Some(field));
  }

  public static function fromParseResult<T>(input : String, result : Result<T>) : ParseError<T> {
    var message = Parsihax.formatError(result, input);
    return new ParseError(
      'Failed to parse expression `$input`: $message',
      input,
      result,
      None
    );
  }

  public override function toString() : String {
    var fieldPart = field.cataf(
      () -> "",
      field -> 'For field "$field": '
    );
    return '${fieldPart}${message}';
  }
}
