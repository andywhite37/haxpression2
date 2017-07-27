package haxpression2;

using thx.Arrays;
import thx.Either;
using thx.Eithers;
import thx.Nel;
import thx.Validation;
import thx.Validation.*;

using haxpression2.Expr;
import haxpression2.ExprParser;
using haxpression2.Value;

class FloatExpr {
  public static function eval(input: String, parserOptions: ExprParserOptions<Value<Float>, Float, ParseMeta>, evalOptions: EvalOptions<Value<Float>>) : VNel<String, Value<Float>> {
    return ExprParser.parse(input, parserOptions)
      .leftMap(e -> e.toString())
      .map(ae -> ae.expr)
      .toVNel()
      .flatMapV(expr -> Exprs.eval(expr, evalOptions));
  }

  public static function toString(expr : Expr<Value<Float>, ParseMeta>) : String {
    return expr.toString(
      value -> value.toString(Std.string)
    );
  }

  public static function roundTrip(input : String, options: ExprParserOptions<Value<Float>, Float, ParseMeta>) : Either<ParseError<AnnotatedExpr<Value<Float>, ParseMeta>>, String> {
    return ExprParser.parse(input, options)
      .map(ae -> toString(ae.expr));
  }

  public static function roundTripOrThrow(input : String, options: ExprParserOptions<Value<Float>, Float, ParseMeta>) : String {
    return switch roundTrip(input, options) {
      case Left(error) : throw error;
      case Right(str) : str;
    };
  }

  public static function ensureNumeric(value : Value<Float>) : Either<String, Value<Float>> {
    return switch value {
      case v = VInt(i) : Right(v);
      case v = VNum(f) : Right(v);
      case VStr(v) : Left('string value "$v" is not numeric');
      case VBool(v) : Left('boolean value $v is not numeric');
    };
  }

  public static function reduceNumericValues(
    values : Array<Value<Float>>,
    intInt : Int -> Int -> VNel<String, Value<Float>>,
    intFloat : Int -> Float -> VNel<String, Float>,
    floatInt : Float -> Int -> VNel<String, Float>,
    floatFloat : Float -> Float -> VNel<String, Float>,
    start : Value<Float>
  ) : VNel<String, Value<Float>> {
    return values.reduce(function(accVNel : VNel<String, Value<Float>>, value: Value<Float>) : VNel<String, Value<Float>> {
      return accVNel.flatMapV(acc ->
        switch [acc, value] {
          case [VInt(a), VInt(b)] : intInt(a, b);
          case [VInt(a), VNum(b)] : intFloat(a, b).map(VNum);
          case [VNum(a), VInt(b)] : floatInt(a, b).map(VNum);
          case [VNum(a), VNum(b)] : floatFloat(a, b).map(VNum);
          case _ : Validation.failureNel('failure');
        }
      );
      return accVNel;
    }, Validation.successNel(start));
  }

  public static function sum(values : Array<Value<Float>>) : VNel<String, Value<Float>> {
    return reduceNumericValues(values,
      (a, b) -> Validation.successNel(a + b).map(VInt),
      (a, b) -> Validation.successNel(a + b),
      (a, b) -> Validation.successNel(a + b),
      (a, b) -> Validation.successNel(a + b),
      Values.int(0)
    );
  }

  public static function add(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceNumericValues([r],
      (a, b) -> Validation.successNel(a + b).map(VInt),
      (a, b) -> Validation.successNel(a + b),
      (a, b) -> Validation.successNel(a + b),
      (a, b) -> Validation.successNel(a + b),
      l
    );
  }

  public static function sub(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceNumericValues([r],
      (a, b) -> Validation.successNel(a - b).map(VInt),
      (a, b) -> Validation.successNel(a - b),
      (a, b) -> Validation.successNel(a - b),
      (a, b) -> Validation.successNel(a - b),
      l
    );
  }

  public static function mul(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceNumericValues([r],
      (a, b) -> Validation.successNel(a * b).map(VInt),
      (a, b) -> Validation.successNel(a * b),
      (a, b) -> Validation.successNel(a * b),
      (a, b) -> Validation.successNel(a * b),
      l
    );
  }

  public static function div(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceNumericValues([r],
      (a, b) -> Validation.successNel(a / b).map(VNum),
      (a, b) -> Validation.successNel(a / b),
      (a, b) -> Validation.successNel(a / b),
      (a, b) -> Validation.successNel(a / b),
      l
    );
  }
}
