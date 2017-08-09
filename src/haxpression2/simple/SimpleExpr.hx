package haxpression2.simple;

using thx.Arrays;
import thx.Either;
import thx.Validation;
import thx.Validation.*;

import thx.schema.SimpleSchema;

import haxpression2.BinOp;
import haxpression2.Expr;
import haxpression2.UnOp;
import haxpression2.AnnotatedExprGroup;
import haxpression2.eval.ExprEvaluator;
import haxpression2.eval.EvalError;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
import haxpression2.parse.ParseMeta;
import haxpression2.render.AnnotatedExprRenderer;
import haxpression2.render.ExprRenderer;
import haxpression2.schema.AnnotatedExprSchema;
import haxpression2.schema.ExprSchema;
import haxpression2.schema.ParseMetaSchema;
import haxpression2.simple.SimpleValue;

// Specialized type aliases

typedef SimpleExpr = Expr<SimpleValue, ParseMeta>;
typedef SimpleAnnotatedExpr = AnnotatedExpr<SimpleValue, ParseMeta>;

typedef SimpleParserOptions = ExprParserOptions<SimpleValue, Float, ParseMeta>;
typedef SimpleParseError = ParseError<SimpleAnnotatedExpr>;
typedef SimpleParseResult = Either<SimpleParseError, SimpleAnnotatedExpr>;

typedef SimpleEvalUnOp = EvalUnOp<SimpleValue>;
typedef SimpleEvalBinOp = EvalBinOp<SimpleValue>;
typedef SimpleEvalFunc = EvalFunc<SimpleValue>;
typedef SimpleEvalError = EvalError<SimpleAnnotatedExpr>;
typedef SimpleEvalOptions = EvalOptions<SimpleAnnotatedExpr, SimpleEvalError, SimpleValue, ParseMeta>;
typedef SimpleEvalResult = EvalResult<SimpleAnnotatedExpr, SimpleEvalError, SimpleValue>;
typedef SimpleEvalStringResult = EvalStringResult<SimpleAnnotatedExpr, SimpleParseError, SimpleEvalError, SimpleValue>;

typedef SimpleFormatStringResult = Either<SimpleParseError, String>;

typedef SimpleAnnotatedExprGroup<A> = AnnotatedExprGroup<SimpleValue, A>;

// Specialized wrapper classes

class SimpleExprSchema {
  public static function schema<E>() : Schema<E, SimpleExpr> {
    return ExprSchema.schema(SimpleValueSchema.schema(), ParseMetaSchema.schema());
  }
}

class SimpleAnnotatedExprSchema {
  public static function schema<E>() : Schema<E, SimpleAnnotatedExpr> {
    return AnnotatedExprSchema.schema(SimpleValueSchema.schema(), ParseMetaSchema.schema());
  }
}

class SimpleExprParser {
  public static function parseString(input : String, options: SimpleParserOptions) : SimpleParseResult {
    return ExprParser.parseString(input, options);
  }

  public static function parseStrings(input : Array<String>, options : SimpleParserOptions) : VNel<ParseError<SimpleAnnotatedExpr>, Array<SimpleAnnotatedExpr>> {
    return ExprParser.parseStrings(input, options);
  }

  public static function parseStringMap(input : Map<String, String>, options : SimpleParserOptions) : VNel<ParseError<SimpleAnnotatedExpr>, Map<String, SimpleAnnotatedExpr>> {
    return ExprParser.parseStringMap(input, options);
  }
}

class SimpleExprRenderer {
  public static function renderString(expr : SimpleExpr) : String {
    return ExprRenderer.renderString(expr, SimpleValueRenderer.renderString);
  }

  public static function formatString(input : String, options: SimpleParserOptions) : SimpleFormatStringResult {
    return ExprRenderer.formatString(input, options, SimpleValueRenderer.renderString);
  }
}

class SimpleAnnotatedExprRenderer {
  public static function renderJSONString<E, A>(ae : AnnotatedExpr<SimpleValue, A>, valueSchema : Schema<E, SimpleValue>, annotationSchema : Schema<E, A>) : String {
    return AnnotatedExprRenderer.renderJSONString(ae, valueSchema, annotationSchema);
  }
}

class SimpleAnnotatedExprEvaluator {
  public static function eval(expr : SimpleAnnotatedExpr, evalOptions: SimpleEvalOptions) : SimpleEvalResult {
    return AnnotatedExprEvaluator.eval(expr, evalOptions);
  }

  public static function evalString(input: String, parserOptions: SimpleParserOptions, evalOptions: SimpleEvalOptions) : SimpleEvalStringResult {
    return AnnotatedExprEvaluator.evalString(input, parserOptions, evalOptions);
  }
}

class SimpleAnnotatedExprGroups {
  public static function renderString<A>(group : SimpleAnnotatedExprGroup<A>, metaToString : A -> String) : String {
    return AnnotatedExprGroup.renderString(group, SimpleValueRenderer.renderString, metaToString);
  }
}

class SimpleExprs {
  public static function getStandardParserOptions() : SimpleParserOptions {
    return {
      variableNameRegexp: ~/[a-z][a-z0-9]*(?:!?[a-z0-9]+)?/i,
      functionNameRegexp: ~/[a-z][a-z0-9]*/i,
      binOps: SimpleExprs.getStandardBinOps(),
      unOps: SimpleExprs.getStandardUnOps(),
      parseDecimal: Std.parseFloat,
      convertValue: thx.Functions.identity,
      annotate: ParseMeta.new
    };
  }

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

  public static function getStandardEvalBinOps() : Map<String, EvalBinOp<SimpleValue>> {
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

  public static function getStandardEvalUnOps() : { pre: Map<String, SimpleEvalUnOp>, post: Map<String, SimpleEvalUnOp> } {
    return {
      pre: [
        "-" => negate,
        "~" => not
      ],
      post: new Map()
    };
  }

  public static function getStandardEvalFunctions() : Map<String, SimpleEvalFunc> {
    return [
      "sum" => sum
    ];
  }

  public static function reduceValues(options: {
    values : Array<SimpleValue>,
    intInt : Int -> Int -> VNel<String, SimpleValue>,
    intFloat : Int -> Float -> VNel<String, SimpleValue>,
    floatInt : Float -> Int -> VNel<String, SimpleValue>,
    floatFloat : Float -> Float -> VNel<String, SimpleValue>,
    stringString : String -> String -> VNel<String, SimpleValue>,
    boolBool : Bool -> Bool -> VNel<String, SimpleValue>
  }) : VNel<String, SimpleValue> {
    return if (options.values.length == 0) {
      failureNel('cannot reduce empty list of values');
    } else {
      options.values.tail().reduce(function(accVNel : VNel<String, SimpleValue>, value: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function sum(values : Array<SimpleValue>) : VNel<String, SimpleValue> {
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

  public static function add(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function sub(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function mul(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function div(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function or(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function and(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function eq(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function neq(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function lt(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function lte(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function gt(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function gte(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
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

  public static function negate(operand : SimpleValue) : VNel<String, SimpleValue> {
    return switch operand {
      case VNA : successNel(VNA);
      case VNM : successNel(VNM);
      case VInt(v) : successNel(VInt(-v));
      case VNum(v) : successNel(VNum(-v));
      case VStr(v) : failureNel('cannot negate string value: $v');
      case VBool(v) : failureNel('cannot negate bool value: $v');
    };
  }

  public static function increment(operand : SimpleValue) : VNel<String, SimpleValue> {
    return switch operand {
      case VNA : successNel(VNA);
      case VNM : successNel(VNM);
      case VInt(v) : successNel(VInt(v + 1));
      case VNum(v) : successNel(VNum(v + 1));
      case VStr(v) : failureNel('cannot increment string value: $v');
      case VBool(v) : failureNel('cannot increment bool value: $v');
    };
  }

  public static function not(operand : SimpleValue) : VNel<String, SimpleValue> {
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
