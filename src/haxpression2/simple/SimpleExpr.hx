package haxpression2.simple;

import Parsihax;

using thx.Arrays;
import thx.Validation;
import thx.Validation.*;

import thx.schema.SimpleSchema;

import haxpression2.Expr;
import haxpression2.AnnotatedExprGroup;
import haxpression2.eval.AnnotatedExprEvaluator;
import haxpression2.eval.EvalError;
import haxpression2.eval.ExprEvaluatorOptions;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ExprParserBinOp;
import haxpression2.parse.ExprParserUnOp;
import haxpression2.parse.ParseError;
import haxpression2.parse.ParseMeta;
import haxpression2.render.AnnotatedExprRenderer;
import haxpression2.render.ExprRenderer;
import haxpression2.schema.AnnotatedExprSchema;
import haxpression2.schema.ExprSchema;
import haxpression2.schema.ParseMetaSchema;
import haxpression2.simple.SimpleValue;

// Specialized type aliases

typedef SimpleExpr<A> = Expr<SimpleValue, A>;
typedef SimpleAnnotatedExpr<A> = AnnotatedExpr<SimpleValue, A>;

typedef SimpleExprParserOptions<A> = ExprParserOptions<SimpleValue, Float, A>;
typedef SimpleParseError<A> = ParseError<SimpleAnnotatedExpr<A>>;
typedef SimpleExprParserResult<A> = ExprParserResult<SimpleValue, A>;

typedef SimpleExprEvaluatorUnOp = ExprEvaluatorUnOp<SimpleValue>;
typedef SimpleExprEvaluatorBinOp = ExprEvaluatorBinOp<SimpleValue>;
typedef SimpleExprEvaluatorFunc = ExprEvaluatorFunc<SimpleValue>;

typedef SimpleEvalError<TExpr> = EvalError<TExpr>;
typedef SimpleExprEvaluatorOptions<TExpr> = ExprEvaluatorOptions<TExpr, SimpleEvalError<TExpr>, SimpleValue>;
typedef SimpleExprEvaluatorResult<TExpr> = ExprEvaluatorResult<TExpr, SimpleEvalError<TExpr>, SimpleValue>;
typedef SimpleExprStringEvaluatorResult<TExpr, A> = ExprStringEvaluatorResult<TExpr, SimpleParseError<A>, SimpleEvalError<TExpr>, SimpleValue>;

typedef SimpleExprFormatStringResult = ExprFormatStringResult<SimpleValue, ParseMeta>;

typedef SimpleAnnotatedExprGroup<A> = AnnotatedExprGroup<SimpleValue, A>;

// Specialized wrapper classes

class SimpleExprSchema {
  public static function schema<E>() : Schema<E, SimpleExpr<ParseMeta>> {
    return ExprSchema.schema(SimpleValueSchema.schema(), ParseMetaSchema.schema());
  }
}

class SimpleAnnotatedExprSchema {
  public static function schema<E>() : Schema<E, SimpleAnnotatedExpr<ParseMeta>> {
    return AnnotatedExprSchema.schema(SimpleValueSchema.schema(), ParseMetaSchema.schema());
  }
}

class SimpleExprParser {
  public static function parseString(input : String, options: SimpleExprParserOptions<ParseMeta>) : SimpleExprParserResult<ParseMeta> {
    return ExprParser.parseString(input, options);
  }

  public static function parseStrings(input : Array<String>, options : SimpleExprParserOptions<ParseMeta>) : VNel<ParseError<SimpleAnnotatedExpr<ParseMeta>>, Array<SimpleAnnotatedExpr<ParseMeta>>> {
    return ExprParser.parseStrings(input, options);
  }

  public static function parseStringMap(input : Map<String, String>, options : SimpleExprParserOptions<ParseMeta>) : VNel<ParseError<SimpleAnnotatedExpr<ParseMeta>>, Map<String, SimpleAnnotatedExpr<ParseMeta>>> {
    return ExprParser.parseStringMap(input, options);
  }
}

class SimpleExprRenderer {
  public static function renderString<A>(expr : Expr<SimpleValue, A>) : String {
    return ExprRenderer.renderString(expr, SimpleValueRenderer.renderString);
  }

  public static function formatString(input : String, options: SimpleExprParserOptions<ParseMeta>) : SimpleExprFormatStringResult {
    return ExprRenderer.formatString(input, options, SimpleValueRenderer.renderString);
  }
}

class SimpleAnnotatedExprRenderer {
  public static function renderJSONString<E, A>(ae : AnnotatedExpr<SimpleValue, A>, valueSchema : Schema<E, SimpleValue>, annotationSchema : Schema<E, A>) : String {
    return AnnotatedExprRenderer.renderJSONString(ae, valueSchema, annotationSchema);
  }
}

class SimpleAnnotatedExprEvaluator {
  public static function eval<A>(expr : SimpleAnnotatedExpr<A>, evalOptions: SimpleExprEvaluatorOptions<SimpleAnnotatedExpr<A>>) : SimpleExprEvaluatorResult<SimpleAnnotatedExpr<A>> {
    return AnnotatedExprEvaluator.eval(expr, evalOptions);
  }

  public static function evalString<A>(input: String, parserOptions: SimpleExprParserOptions<A>, evalOptions: SimpleExprEvaluatorOptions<SimpleAnnotatedExpr<A>>) : SimpleExprStringEvaluatorResult<SimpleAnnotatedExpr<A>, A> {
    return AnnotatedExprEvaluator.evalString(input, parserOptions, evalOptions);
  }
}

class SimpleAnnotatedExprGroupRenderer {
  public static function renderPlainString<A>(group : SimpleAnnotatedExprGroup<A>, metaToString : A -> String) : String {
    return AnnotatedExprGroup.renderPlainString(group, SimpleValueRenderer.renderString, metaToString);
  }

  public static function renderJSONString<E, A>(group : SimpleAnnotatedExprGroup<A>, metaSchema : Schema<E, A>) : String {
    return AnnotatedExprGroup.renderJSONString(group, SimpleValueSchema.schema(), metaSchema);
  }
}

class SimpleExprs {
  public static function getStandardExprParserOptions<A>(options: { annotate : Index -> A }) : SimpleExprParserOptions<A> {
    return {
      variableNameRegexp: ~/[a-z_][a-z0-9_]*(?:!?[a-z0-9_]+)?/i,
      functionNameRegexp: ~/[a-z_][a-z0-9_]*/i,
      binOps: SimpleExprs.getStandardExprParserBinOps(),
      unOps: SimpleExprs.getStandardExprParserUnOps(),
      parseReal: Std.parseFloat,
      convertValue: thx.Functions.identity,
      annotate: options.annotate
    };
  }

  // https://www.haskell.org/onlinereport/haskell2010/haskellch4.html#x10-820004.4.2
  public static function getStandardExprParserBinOps() : Array<ExprParserBinOp> {
    return [
      new ExprParserBinOp(~/\*|\//, 7),
      new ExprParserBinOp(~/\+|-/, 6),
      new ExprParserBinOp(~/==|!=|<=|<|>=|>/, 4),
      new ExprParserBinOp(~/&&/, 3),
      new ExprParserBinOp(~/\|\|/, 2)
    ];
  }

  public static function getStandardExprEvaluatorBinOps() : Map<String, ExprEvaluatorBinOp<SimpleValue>> {
    return [
      "*" => { eval: mul },
      "/" => { eval: safeDiv },
      "+" => { eval: add },
      "-" => { eval: sub },
      "==" => { eval: eq },
      "!=" => { eval: neq },
      "<" => { eval: lt },
      "<=" => { eval: lte },
      ">" => { eval: gt },
      ">=" => { eval: gte },
      "&&" => { eval: and },
      "||" => { eval: or }
    ];
  }

  public static function getStandardExprParserUnOps() : { pre: Array<ExprParserUnOp>, post: Array<ExprParserUnOp> } {
    return {
      pre: [
        // TODO: I don't think the precedence of these really has any impact
        new ExprParserUnOp(~/-/, 2),
        new ExprParserUnOp(~/~/, 1),
      ],
      post: [
      ]
    };
  }

  public static function getStandardExprEvaluatorUnOps() : { pre: Map<String, SimpleExprEvaluatorUnOp>, post: Map<String, SimpleExprEvaluatorUnOp> } {
    return {
      pre: [
        "-" => { eval: negate },
        "~" => { eval: not }
      ],
      post: new Map()
    };
  }

  public static function getStandardExprEvaluatorFuncs() : Map<String, SimpleExprEvaluatorFunc> {
    return [
      "sum" => { arity: Variable, eval: sum }
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
            case [VInt(a), VReal(b)] : options.intFloat(a, b);
            case [VReal(a), VInt(b)] : options.floatInt(a, b);
            case [VReal(a), VReal(b)] : options.floatFloat(a, b);
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
      intFloat: (a, b) -> successNel(a + b).map(VReal),
      floatInt: (a, b) -> successNel(a + b).map(VReal),
      floatFloat: (a, b) -> successNel(a + b).map(VReal),
      stringString: (a, b) -> successNel(a + b).map(VStr),
      boolBool: (a, b) -> failureNel('cannot sum boolean values')
    });
  }

  public static function add(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> successNel(a + b).map(VInt),
      intFloat: (a, b) -> successNel(a + b).map(VReal),
      floatInt: (a, b) -> successNel(a + b).map(VReal),
      floatFloat: (a, b) -> successNel(a + b).map(VReal),
      stringString: (a, b) -> successNel(a + b).map(VStr),
      boolBool: (a, b) -> failureNel('cannot add boolean values')
    });
  }

  public static function sub(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> successNel(a - b).map(VInt),
      intFloat: (a, b) -> successNel(a - b).map(VReal),
      floatInt: (a, b) -> successNel(a - b).map(VReal),
      floatFloat: (a, b) -> successNel(a - b).map(VReal),
      stringString: (a, b) -> failureNel('cannot subtract string values'),
      boolBool: (a, b) -> failureNel('cannot subtract bool values')
  });
  }

  public static function mul(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> successNel(a * b).map(VInt),
      intFloat: (a, b) -> successNel(a * b).map(VReal),
      floatInt: (a, b) -> successNel(a * b).map(VReal),
      floatFloat: (a, b) -> successNel(a * b).map(VReal),
      stringString: (a, b) -> failureNel('cannot multiply string values'),
      boolBool: (a, b) -> failureNel('cannot multiply bool values')
    });
  }

  public static function safeDiv(l : SimpleValue, r: SimpleValue) : VNel<String, SimpleValue> {
    return reduceValues({
      values: [l, r],
      intInt: (a, b) -> b == 0 ? successNel(VNM) : successNel(a / b).map(VReal),
      intFloat: (a, b) -> b == 0 ? successNel(VNM) : successNel(a / b).map(VReal),
      floatInt: (a, b) -> b == 0 ? successNel(VNM) : successNel(a / b).map(VReal),
      floatFloat: (a, b) -> b == 0 ? successNel(VNM) : successNel(a / b).map(VReal),
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
      case VReal(v) : successNel(VReal(-v));
      case VStr(v) : failureNel('cannot negate string value: $v');
      case VBool(v) : failureNel('cannot negate bool value: $v');
    };
  }

  public static function increment(operand : SimpleValue) : VNel<String, SimpleValue> {
    return switch operand {
      case VNA : successNel(VNA);
      case VNM : successNel(VNM);
      case VInt(v) : successNel(VInt(v + 1));
      case VReal(v) : successNel(VReal(v + 1));
      case VStr(v) : failureNel('cannot increment string value: $v');
      case VBool(v) : failureNel('cannot increment bool value: $v');
    };
  }

  public static function not(operand : SimpleValue) : VNel<String, SimpleValue> {
    return switch operand {
      case VNA : failureNel('cannot `not` NA value');
      case VNM : failureNel('cannot `not` NM value');
      case VInt(v) : failureNel('cannot `not` int value: $v');
      case VReal(v) : failureNel('cannot `not` float value: $v');
      case VStr(v) : failureNel('cannot `not` string value: $v');
      case VBool(v) : successNel(VBool(!v));
    };
  }
}
