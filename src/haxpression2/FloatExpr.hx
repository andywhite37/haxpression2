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

typedef FloatAnnotatedExpr = AnnotatedExpr<Value<Float>, ParseMeta>;
typedef FloatExprParseResult = Either<ParseError<FloatAnnotatedExpr>, FloatAnnotatedExpr>;
typedef FloatExprRoundTripResult = Either<ParseError<FloatAnnotatedExpr>, String>;
typedef FloatExprEvalResult = VNel<String, Value<Float>>; //Either<ParseError<FloatAnnotatedExpr>, String>;

class FloatExpr {
  public static function valueToString(value : Value<Float>) : String {
    return value.toString(Std.string);
  }

  public static function toString(expr : Expr<Value<Float>, ParseMeta>) : String {
    return expr.toString(
      value -> value.toString(Std.string)
    );
  }

  public static function parse(input : String, parserOptions: ExprParserOptions<Value<Float>, Float, ParseMeta>) : FloatExprParseResult {
    return ExprParser.parse(input, parserOptions);
  }

  public static function roundTrip(input : String, options: ExprParserOptions<Value<Float>, Float, ParseMeta>) : FloatExprRoundTripResult {
    return ExprParser.parse(input, options)
      .map(ae -> toString(ae.expr));
  }

  public static function eval(input: String, parserOptions: ExprParserOptions<Value<Float>, Float, ParseMeta>, evalOptions: EvalOptions<Value<Float>>) : FloatExprEvalResult {
    return ExprParser.parse(input, parserOptions)
      .leftMap(e -> e.toString())
      .map(ae -> ae.expr)
      .toVNel()
      .flatMapV(expr -> Exprs.eval(expr, evalOptions));
  }

  public static function ensureNumeric(value : Value<Float>) : Either<String, Value<Float>> {
    return switch value {
      case v = VInt(i) : Right(v);
      case v = VNum(f) : Right(v);
      case VStr(v) : Left('string value "$v" is not numeric');
      case VBool(v) : Left('boolean value $v is not numeric');
    };
  }

  public static function reduceValues(
    values : Array<Value<Float>>,
    intInt : Int -> Int -> VNel<String, Value<Float>>,
    intFloat : Int -> Float -> VNel<String, Value<Float>>,
    floatInt : Float -> Int -> VNel<String, Value<Float>>,
    floatFloat : Float -> Float -> VNel<String, Value<Float>>,
    stringString : String -> String -> VNel<String, Value<Float>>,
    boolBool : Bool -> Bool -> VNel<String, Value<Float>>
  ) : VNel<String, Value<Float>> {
    return if (values.length == 0) {
      failureNel('cannot reduce empty list of values');
    } else {
      values.tail().reduce(function(accVNel : VNel<String, Value<Float>>, value: Value<Float>) : VNel<String, Value<Float>> {
        return accVNel.flatMapV(acc ->
          switch [acc, value] {
            case [VInt(a), VInt(b)] : intInt(a, b);
            case [VInt(a), VNum(b)] : intFloat(a, b);
            case [VNum(a), VInt(b)] : floatInt(a, b);
            case [VNum(a), VNum(b)] : floatFloat(a, b);
            case [VStr(a), VStr(b)] : stringString(a, b);
            case [VBool(a), VBool(b)] : boolBool(a, b);
            case [l = _, r = _] : Validation.failureNel('cannot reduce values `$l` and `$r`');
          }
        );
        return accVNel;
      }, Validation.successNel(values.head()));
    }
  }

  public static function sum(values : Array<Value<Float>>) : VNel<String, Value<Float>> {
    return reduceValues(
      values,
      (a, b) -> Validation.successNel(a + b).map(VInt),
      (a, b) -> Validation.successNel(a + b).map(VNum),
      (a, b) -> Validation.successNel(a + b).map(VNum),
      (a, b) -> Validation.successNel(a + b).map(VNum),
      (a, b) -> Validation.successNel(a + b).map(VStr),
      (a, b) -> Validation.failureNel('cannot sum boolean values')
    );
  }

  public static function add(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues(
      [l, r],
      (a, b) -> Validation.successNel(a + b).map(VInt),
      (a, b) -> Validation.successNel(a + b).map(VNum),
      (a, b) -> Validation.successNel(a + b).map(VNum),
      (a, b) -> Validation.successNel(a + b).map(VNum),
      (a, b) -> Validation.successNel(a + b).map(VStr),
      (a, b) -> Validation.failureNel('cannot add boolean values')
    );
  }

  public static function sub(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues(
      [l, r],
      (a, b) -> Validation.successNel(a - b).map(VInt),
      (a, b) -> Validation.successNel(a - b).map(VNum),
      (a, b) -> Validation.successNel(a - b).map(VNum),
      (a, b) -> Validation.successNel(a - b).map(VNum),
      (a, b) -> Validation.failureNel('cannot subtract string values'),
      (a, b) -> Validation.failureNel('cannot subtract bool values')
    );
  }

  public static function mul(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues(
      [l, r],
      (a, b) -> Validation.successNel(a * b).map(VInt),
      (a, b) -> Validation.successNel(a * b).map(VNum),
      (a, b) -> Validation.successNel(a * b).map(VNum),
      (a, b) -> Validation.successNel(a * b).map(VNum),
      (a, b) -> Validation.failureNel('cannot multiply string values'),
      (a, b) -> Validation.failureNel('cannot multiply bool values')
    );
  }

  public static function div(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues(
      [l, r],
      (a, b) -> Validation.successNel(a / b).map(VNum),
      (a, b) -> Validation.successNel(a / b).map(VNum),
      (a, b) -> Validation.successNel(a / b).map(VNum),
      (a, b) -> Validation.successNel(a / b).map(VNum),
      (a, b) -> Validation.failureNel('cannot divide string values'),
      (a, b) -> Validation.failureNel('cannot divide bool values')
    );
  }

  public static function or(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return switch [l, r] {
      case [VBool(l), VBool(r)] : successNel(VBool(l || r));
      case [l = _, r = _] : failureNel('cannot `or` non-bool values: $l and $r');
    };
  }

  public static function and(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return switch [l, r] {
      case [VBool(l), VBool(r)] : successNel(VBool(l && r));
      case [l = _, r = _] : failureNel('cannot `and` non-bool values: $l and $r');
    };
  }

  public static function negate(operand : Value<Float>) : VNel<String, Value<Float>> {
    return switch operand {
      case VInt(v) : successNel(VInt(-v));
      case VNum(v) : successNel(VNum(-v));
      case VStr(v) : failureNel('cannot negate string value: $v');
      case VBool(v) : failureNel('cannot negate bool value: $v');
    };
  }

  public static function increment(operand : Value<Float>) : VNel<String, Value<Float>> {
    return switch operand {
      case VInt(v) : successNel(VInt(v + 1));
      case VNum(v) : successNel(VNum(v + 1));
      case VStr(v) : failureNel('cannot increment string value: $v');
      case VBool(v) : failureNel('cannot increment bool value: $v');
    };
  }

  public static function not(operand : Value<Float>) : VNel<String, Value<Float>> {
    return switch operand {
      case VInt(v) : failureNel('cannot `not` int value: $v');
      case VNum(v) : failureNel('cannot `not` float value: $v');
      case VStr(v) : failureNel('cannot `not` string value: $v');
      case VBool(v) : successNel(VBool(!v));
    };
  }
}
