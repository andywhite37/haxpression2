package haxpression2;

import thx.Either;

import Parsihax.*;
using Parsihax;

import haxpression2.CoreParser as C;
import haxpression2.Value;

typedef ValueParserOptions<D> = {
  parseDecimal : String -> D
};

typedef ValueParsers<D> = {
  value: Parser<Value<D>>,
  _internal: {
    valueNum: Parser<Value<D>>,
    valueInt: Parser<Value<D>>,
    valueStr: Parser<Value<D>>,
    valueBool: Parser<Value<D>>,
  }
};

class ValueParser {
  public static function create<D>(options: ValueParserOptions<D>) : ValueParsers<D> {
    var valueNum = C.decimalString.map(options.parseDecimal).map(VNum);
    var valueInt = C.integer.map(VInt);
    var valueStr = C.string.map(VStr);
    var valueBool = C.bool.map(VBool);
    var value = choice([valueNum, valueInt, valueStr, valueBool]);
    return {
      value: value,
      _internal: {
        valueNum: valueNum,
        valueInt: valueInt,
        valueStr: valueStr,
        valueBool: valueBool,
      }
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
