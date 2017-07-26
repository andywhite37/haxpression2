package haxpression2;

import thx.Either;

import parsihax.ParseObject;
import parsihax.ParseResult;
import parsihax.Parser.*;
using parsihax.Parser;

import haxpression2.CoreParser as C;
import haxpression2.Value;

typedef ValueParserOptions<N, A> = {
  convertFloat : Float -> N,
  meta: Int -> A
};

class ValueParser {
  public static function valueInt<N, A>(options: ValueParserOptions<N, A>) : ParseObject<Value<N, A>> {
    return index().flatMap(index ->
      C.integer.map(v -> VInt(v, options.meta(index)))
    );
  }

  public static function valueNum<N, A>(options: ValueParserOptions<N, A>) : ParseObject<Value<N, A>> {
    return index().flatMap(index ->
      C.float.map(options.convertFloat).map(v -> VNum(v, options.meta(index)))
    );
  }

  public static function valueStr<N, A>(options: ValueParserOptions<N, A>) : ParseObject<Value<N, A>> {
    return index().flatMap(index ->
      C.string.map(v -> VStr(v, options.meta(index)))
    );
  }

  public static function valueBool<N, A>(options: ValueParserOptions<N, A>) : ParseObject<Value<N, A>> {
    return index().flatMap(index ->
      C.bool.map(v -> VBool(v, options.meta(index)))
    );
  }

  public static function value<N, A>(options : ValueParserOptions<N, A>) : ParseObject<Value<N, A>> {
    return C.ows
      .then(alt([
        valueNum(options),
        valueInt(options),
        valueStr(options),
        valueBool(options)
      ]))
      .skip(C.ows);
  }


  public static function parse<N, A>(input : String, options: ValueParserOptions<N, A>) : Either<ParseError, Value<N, A>> {
    var parseResult = value(options).skip(eof()).apply(input);
    return if (parseResult.status) {
      Right(parseResult.value);
    } else {
      Left(ParseError.fromParseResult(input, parseResult));
    }
  }
}
