package haxpression2.simple;

using thx.Arrays;
import thx.Either;
using thx.Eithers;
import thx.Nel;
import thx.Validation;
import thx.Validation.*;

import haxpression2.BinOp;
using haxpression2.Expr;
import haxpression2.UnOp;
using haxpression2.Value;
using haxpression2.eval.ExprEvaluator;
import haxpression2.eval.EvalError;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
import haxpression2.parse.ParseMeta;
using haxpression2.render.ExprRenderer;
using haxpression2.render.ValueRenderer;

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
typedef FloatParseEvalResult = ParseEvalResult<FloatAnnotatedExpr, FloatParseError, FloatEvalError, FloatValue>;

typedef FloatParseRenderResult = Either<FloatParseError, String>;

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

  public static function renderValue(value : Value<Float>) : String {
    return value.render(Std.string);
  }

  public static function renderExpr(expr : FloatExpr) : String {
    return expr.render(renderValue);
  }

  public static function parse(input : String, options: FloatParserOptions) : FloatParseResult {
    return ExprParser.parse(input, options);
  }

  public static function parseRender(input : String, options: FloatParserOptions) : FloatParseRenderResult {
    return ExprRenderer.parseRender(input, options, renderValue);
  }

  public static function parseEval(input: String, parserOptions: FloatParserOptions, evalOptions: FloatEvalOptions) : FloatParseEvalResult {
    return AnnotatedExprEvaluator.parseEval(input, parserOptions, evalOptions);
  }

  public static function reduceValues(options: {
    values : Array<Value<Float>>,
    intInt : Int -> Int -> VNel<String, Value<Float>>,
    intFloat : Int -> Float -> VNel<String, Value<Float>>,
    floatInt : Float -> Int -> VNel<String, Value<Float>>,
    floatFloat : Float -> Float -> VNel<String, Value<Float>>,
    stringString : String -> String -> VNel<String, Value<Float>>,
    boolBool : Bool -> Bool -> VNel<String, Value<Float>>
  }) : VNel<String, Value<Float>> {
    return if (options.values.length == 0) {
      failureNel('cannot reduce empty list of values');
    } else {
      options.values.tail().reduce(function(accVNel : VNel<String, Value<Float>>, value: Value<Float>) : VNel<String, Value<Float>> {
        return accVNel.flatMapV(acc ->
          switch [acc, value] {
            case [VNA, _] : successNel(VNA);
            case [_, VNA] : successNel(VNA);
            case [VNM, _] : successNel(VNM);
            case [_, VNM] : successNel(VNM);
            case [VInt(a), VInt(b)] : options.intInt(a, b);
            case [VInt(a), VNum(b)] : options.intFloat(a, b);
            case [VNum(a), VInt(b)] : options.floatInt(a, b);
            case [VNum(a), VNum(b)] : options.floatFloat(a, b);
            case [VStr(a), VStr(b)] : options.stringString(a, b);
            case [VBool(a), VBool(b)] : options.boolBool(a, b);
            case [l = _, r = _] : failureNel('cannot combine values of incompatible types: `$l` and `$r`');
          }
        );
        return accVNel;
      }, successNel(options.values.head()));
    }
  }

  public static function sum(values : Array<Value<Float>>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: values,
      intInt: (a, b) -> successNel(a + b).map(VInt),
      intFloat: (a, b) -> successNel(a + b).map(VNum),
      floatInt: (a, b) -> successNel(a + b).map(VNum),
      floatFloat: (a, b) -> successNel(a + b).map(VNum),
      stringString: (a, b) -> successNel(a + b).map(VStr),
      boolBool: (a, b) -> failureNel('cannot sum boolean values')
    });
  }

  public static function add(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> successNel(a + b).map(VInt),
      intFloat: (a, b) -> successNel(a + b).map(VNum),
      floatInt: (a, b) -> successNel(a + b).map(VNum),
      floatFloat: (a, b) -> successNel(a + b).map(VNum),
      stringString: (a, b) -> successNel(a + b).map(VStr),
      boolBool: (a, b) -> failureNel('cannot add boolean values')
    });
  }

  public static function sub(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> successNel(a - b).map(VInt),
      intFloat: (a, b) -> successNel(a - b).map(VNum),
      floatInt: (a, b) -> successNel(a - b).map(VNum),
      floatFloat: (a, b) -> successNel(a - b).map(VNum),
      stringString: (a, b) -> failureNel('cannot subtract string values'),
      boolBool: (a, b) -> failureNel('cannot subtract bool values')
  });
  }

  public static function mul(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> successNel(a * b).map(VInt),
      intFloat: (a, b) -> successNel(a * b).map(VNum),
      floatInt: (a, b) -> successNel(a * b).map(VNum),
      floatFloat: (a, b) -> successNel(a * b).map(VNum),
      stringString: (a, b) -> failureNel('cannot multiply string values'),
      boolBool: (a, b) -> failureNel('cannot multiply bool values')
    });
  }

  public static function div(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> b == 0 ? successNel(VNM) : successNel(a / b).map(VNum),
      intFloat: (a, b) -> b == 0 ? successNel(VNM) : successNel(a / b).map(VNum),
      floatInt: (a, b) -> b == 0 ? successNel(VNM) : successNel(a / b).map(VNum),
      floatFloat: (a, b) -> b == 0 ? successNel(VNM) : successNel(a / b).map(VNum),
      stringString: (a, b) -> failureNel('cannot divide string values'),
      boolBool: (a, b) -> failureNel('cannot divide bool values')
    });
  }

  public static function or(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> failureNel('cannot `or` int and int values'),
      intFloat: (a, b) -> failureNel('cannot `or` int and float values'),
      floatInt: (a, b) -> failureNel('cannot `or` float and int values'),
      floatFloat: (a, b) -> failureNel('cannot `or` float and float values'),
      stringString: (a, b) -> failureNel('cannot `or` string and string values'),
      boolBool: (a, b) -> successNel(a || b).map(VBool)
    });
  }

  public static function and(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> failureNel('cannot `and` int and int'),
      intFloat: (a, b) -> failureNel('cannot `and` int and float'),
      floatInt: (a, b) -> failureNel('cannot `and` float and int'),
      floatFloat: (a, b) -> failureNel('cannot `and` float and float'),
      stringString: (a, b) -> failureNel('cannot `and` string and string'),
      boolBool: (a, b) -> successNel(a && b).map(VBool)
    });
  }

  public static function eq(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> successNel(a == b).map(VBool),
      intFloat: (a, b) -> successNel(a == b).map(VBool),
      floatInt: (a, b) -> successNel(a == b).map(VBool),
      floatFloat: (a, b) -> successNel(a == b).map(VBool),
      stringString: (a, b) -> successNel(a == b).map(VBool),
      boolBool: (a, b) -> successNel(a == b).map(VBool)
    });
  }

  public static function neq(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> successNel(a != b).map(VBool),
      intFloat: (a, b) -> successNel(a != b).map(VBool),
      floatInt: (a, b) -> successNel(a != b).map(VBool),
      floatFloat: (a, b) -> successNel(a != b).map(VBool),
      stringString: (a, b) -> successNel(a != b).map(VBool),
      boolBool: (a, b) -> successNel(a != b).map(VBool)
    });
  }

  public static function lt(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> successNel(a < b).map(VBool),
      intFloat: (a, b) -> successNel(a < b).map(VBool),
      floatInt: (a, b) -> successNel(a < b).map(VBool),
      floatFloat: (a, b) -> successNel(a < b).map(VBool),
      stringString: (a, b) -> successNel(a < b).map(VBool),
      boolBool: (a, b) -> failureNel('cannot `<` bool and bool')
    });
  }

  public static function lte(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> successNel(a <= b).map(VBool),
      intFloat: (a, b) -> successNel(a <= b).map(VBool),
      floatInt: (a, b) -> successNel(a <= b).map(VBool),
      floatFloat: (a, b) -> successNel(a <= b).map(VBool),
      stringString: (a, b) -> successNel(a <= b).map(VBool),
      boolBool: (a, b) -> failureNel('cannot `<=` bool and bool')
    });
  }

  public static function gt(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> successNel(a > b).map(VBool),
      intFloat: (a, b) -> successNel(a > b).map(VBool),
      floatInt: (a, b) -> successNel(a > b).map(VBool),
      floatFloat: (a, b) -> successNel(a > b).map(VBool),
      stringString: (a, b) -> successNel(a > b).map(VBool),
      boolBool: (a, b) -> failureNel('cannot `>` bool and bool')
    });
  }

  public static function gte(l : Value<Float>, r: Value<Float>) : VNel<String, Value<Float>> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> successNel(a >= b).map(VBool),
      intFloat: (a, b) -> successNel(a >= b).map(VBool),
      floatInt: (a, b) -> successNel(a >= b).map(VBool),
      floatFloat: (a, b) -> successNel(a >= b).map(VBool),
      stringString: (a, b) -> successNel(a >= b).map(VBool),
      boolBool: (a, b) -> failureNel('cannot `>=` bool and bool')
    });
  }

  public static function negate(operand : Value<Float>) : VNel<String, Value<Float>> {
    return switch operand {
      case VNA : successNel(VNA);
      case VNM : successNel(VNM);
      case VInt(v) : successNel(VInt(-v));
      case VNum(v) : successNel(VNum(-v));
      case VStr(v) : failureNel('cannot negate string value: $v');
      case VBool(v) : failureNel('cannot negate bool value: $v');
    };
  }

  public static function increment(operand : Value<Float>) : VNel<String, Value<Float>> {
    return switch operand {
      case VNA : successNel(VNA);
      case VNM : successNel(VNM);
      case VInt(v) : successNel(VInt(v + 1));
      case VNum(v) : successNel(VNum(v + 1));
      case VStr(v) : failureNel('cannot increment string value: $v');
      case VBool(v) : failureNel('cannot increment bool value: $v');
    };
  }

  public static function not(operand : Value<Float>) : VNel<String, Value<Float>> {
    return switch operand {
      case VNA : failureNel('cannot `not` NA value');
      case VNM : failureNel('cannot `not` NM value');
      case VInt(v) : failureNel('cannot `not` int value: $v');
      case VNum(v) : failureNel('cannot `not` float value: $v');
      case VStr(v) : failureNel('cannot `not` string value: $v');
      case VBool(v) : successNel(VBool(!v));
    };
  }
}
