package haxpression2;

import thx.Either;

import Parsihax.*;
using Parsihax;

import haxpression2.CoreParser as C;
import haxpression2.Value;

typedef ValueParserOptions<N> = {
  convertFloat : Float -> N
};

typedef ValueParsers<N> = {
  valueNum: Parser<Value<N>>,
  valueInt: Parser<Value<N>>,
  valueStr: Parser<Value<N>>,
  valueBool: Parser<Value<N>>,
  value: Parser<Value<N>>
};

class ValueParser {
  public static function create<N>(options: ValueParserOptions<N>) : ValueParsers<N> {
    var valueNum = C.float.map(options.convertFloat).map(VNum);
    var valueInt = C.integer.map(VInt);
    var valueStr = C.string.map(VStr);
    var valueBool = C.bool.map(VBool);
    var value = choice([valueNum, valueInt, valueStr, valueBool]);
    return {
      valueNum: valueNum,
      valueInt: valueInt,
      valueStr: valueStr,
      valueBool: valueBool,
      value: value
    };
  }

  public static function parse<N>(input : String, options: ValueParserOptions<N>) : Either<ParseError<Value<N>>, Value<N>> {
    var parseResult = create(options).value.skip(eof()).apply(input);
    return if (parseResult.status) {
      Right(parseResult.value);
    } else {
      Left(ParseError.fromParseResult(input, parseResult));
    }
  }
}
