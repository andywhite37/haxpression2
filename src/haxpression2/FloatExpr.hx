package haxpression2;

using thx.Arrays;
import thx.Either;
using thx.Eithers;
import thx.Nel;
import thx.Validation;
import thx.Validation.*;

import haxpression2.BinOp;
using haxpression2.Expr;
import haxpression2.ExprParser;
import haxpression2.UnOp;
using haxpression2.Value;
import haxpression2.error.EvalError;
import haxpression2.error.ParseError;

typedef FloatValue = Value<Float>;
typedef FloatExpr = Expr<FloatValue, ParseMeta>;
typedef FloatAnnotatedExpr = AnnotatedExpr<FloatValue, ParseMeta>;

typedef FloatParserOptions = ExprParserOptions<FloatValue, Float, ParseMeta>;
typedef FloatParseError = ParseError<FloatAnnotatedExpr>;
typedef FloatParseResult = Either<FloatParseError, FloatAnnotatedExpr>;

typedef FloatEvalUnOp = EvalUnOp<FloatValue>;
typedef FloatEvalBinOp = EvalBinOp<FloatValue>;
typedef FloatEvalFunc = EvalFunc<FloatValue>;
typedef FloatEvalError = EvalError<FloatAnnotatedExpr>;
typedef FloatEvalOptions = EvalOptions<FloatAnnotatedExpr, FloatEvalError, FloatValue, ParseMeta>;
typedef FloatEvalResult = EvalResult<FloatAnnotatedExpr, FloatEvalError, FloatValue>;

enum FloatParseEvalResult {
  ParseError(error : FloatParseError);
  EvalErrors(errors : Nel<{ expr: FloatAnnotatedExpr, error: FloatEvalError }>);
  Success(value : FloatValue);
}

typedef FloatRoundTripResult = Either<FloatParseError, String>;

class FloatExprs {
  // https://www.haskell.org/onlinereport/haskell2010/haskellch4.html#x10-820004.4.2
  public static function getStandardBinOps() : Array<BinOp> {
    return [
      new BinOp(~/\*|\//, 7),           // * /
      new BinOp(~/\+|-/, 6),            // + -
      new BinOp(~/==|!=|<=|<|>=|>/, 4), // == != < <= > >=
      new BinOp(~/&&/, 3),              // &&
      new BinOp(~/\|\|/, 2)            // ||
    ];
  }

  public static function getStandardEvalBinOps() : Map<String, EvalBinOp<Value<Float>>> {
    return [
      "*" => mul,
      "/" => div,
      "+" => add,
      "-" => sub,
      "==" => eq,
      "!=" => neq,
      "<" => lt,
      "<=" => lte,
      ">" => gt,
      ">=" => gte,
      "&&" => and,
      "||" => or
    ];
  }

  public static function getStandardUnOps() : { pre: Array<UnOp>, post: Array<UnOp> } {
    return {
      pre: [
        // TODO: I don't think the precedence of these really has any impact
        new UnOp(~/-/, 2),
        new UnOp(~/~/, 1),
      ],
      post: [
      ]
    };
  }

  public static function getStandardEvalUnOps() : { pre: Map<String, FloatEvalUnOp>, post: Map<String, FloatEvalUnOp> } {
    return {
      pre: [
        "-" => negate,
        "~" => not
      ],
      post: new Map()
    };
  }

  public static function getStandardEvalFunctions() : Map<String, FloatEvalFunc> {
    return [
      "sum" => sum
    ];
  }

  public static function valueToString(value : Value<Float>) : String {
    return value.renderString(Std.string);
  }

  public static function toString(expr : FloatExpr) : String {
    return expr.renderString(
      value -> value.renderString(Std.string)
    );
  }

  public static function parse(input : String, options: FloatParserOptions) : FloatParseResult {
    return ExprParser.parse(input, options);
  }

  public static function roundTrip(input : String, options: FloatParserOptions) : FloatRoundTripResult {
    return ExprParser.parse(input, options)
      .map(ae -> toString(ae.expr));
  }

  public static function parseEval(input: String, parserOptions: FloatParserOptions, evalOptions: FloatEvalOptions) : FloatParseEvalResult {
    return switch ExprParser.parse(input, parserOptions) {
      case Left(parseError) : ParseError(parseError);
      case Right(expr) : switch AnnotatedExpr.eval(expr, evalOptions) {
        case Left(errors) : EvalErrors(errors);
        case Right(value) : Success(value);
      };
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

  public static function eq(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return switch [l, r] {
      case [VInt(l), VInt(r)] : successNel(VBool(l == r));
      case [VNum(l), VNum(r)] : successNel(VBool(l == r));
      case [VStr(l), VStr(r)] : successNel(VBool(l == r));
      case [VBool(l), VBool(r)] : successNel(VBool(l == r));
      case [l = _, r = _] : failureNel('cannot == values of different types');
    };
  }

  public static function neq(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return switch [l, r] {
      case [VInt(l), VInt(r)] : successNel(VBool(l != r));
      case [VNum(l), VNum(r)] : successNel(VBool(l != r));
      case [VStr(l), VStr(r)] : successNel(VBool(l != r));
      case [VBool(l), VBool(r)] : successNel(VBool(l != r));
      case [l = _, r = _] : failureNel('cannot != values of different types');
    };
  }

  public static function lt(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return switch [l, r] {
      case [VInt(l), VInt(r)] : successNel(VBool(l < r));
      case [VNum(l), VNum(r)] : successNel(VBool(l < r));
      case [VStr(l), VStr(r)] : successNel(VBool(l < r));
      case [l = _, r = _] : failureNel('cannot < values of type $l and $r');
    };
  }

  public static function lte(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return switch [l, r] {
      case [VInt(l), VInt(r)] : successNel(VBool(l <= r));
      case [VNum(l), VNum(r)] : successNel(VBool(l <= r));
      case [VStr(l), VStr(r)] : successNel(VBool(l <= r));
      case [l = _, r = _] : failureNel('cannot <= values of type $l and $r');
    };
  }

  public static function gt(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return switch [l, r] {
      case [VInt(l), VInt(r)] : successNel(VBool(l > r));
      case [VNum(l), VNum(r)] : successNel(VBool(l > r));
      case [VStr(l), VStr(r)] : successNel(VBool(l > r));
      case [l = _, r = _] : failureNel('cannot > values of type $l and $r');
    };
  }

  public static function gte(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return switch [l, r] {
      case [VInt(l), VInt(r)] : successNel(VBool(l >= r));
      case [VNum(l), VNum(r)] : successNel(VBool(l >= r));
      case [VStr(l), VStr(r)] : successNel(VBool(l >= r));
      case [l = _, r = _] : failureNel('cannot >= values of type $l and $r');
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
