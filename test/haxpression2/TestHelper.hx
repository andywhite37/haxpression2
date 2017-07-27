package haxpression2;

using thx.Arrays;
import thx.Either;
using thx.Eithers;
import thx.Validation;
import thx.Validation.*;

import haxpression2.BinOp;
using haxpression2.Expr;
import haxpression2.ExprParser;
import haxpression2.ParseMeta;
using haxpression2.Value;

class TestHelper {
  public static function getExprParserOptions() : ExprParserOptions<Value<Float>, Float, ParseMeta> {
    return {
      variableNameRegexp: ~/[a-z][a-z0-9]*(?:!?[a-z0-9]+)?/i,
      functionNameRegexp: ~/[a-z]+/i,
      binOps: BinOp.getStandardBinOps(),
      unOps: {
        pre: [
        ],
        post: [
        ]
      },
      convertFloat: thx.Functions.identity,
      convertValue: thx.Functions.identity,
      annotate: ParseMeta.new
    };
  }

  public static function getEvalOptions() : EvalOptions<Value<Float>> {
    return {
      variables: [
        "a" => Values.int(0),
        "b" => Values.int(1),
        "c" => Values.int(2),
        "x" => Values.int(10),
        "y" => Values.int(-10),
        "z" => Values.int(100)
      ],
      functions: [
        "sum" => FloatExpr.sum
      ],
      binOps: [
        "+" => FloatExpr.add,
        "-" => FloatExpr.sub,
        "*" => FloatExpr.mul,
        "/" => FloatExpr.div
      ]
    };
  }

  public static function roundTrip(input : String) {
    return FloatExpr.roundTripOrThrow(input, getExprParserOptions());
  }

  public static function eval(input : String) {
    return FloatExpr.eval(input, getExprParserOptions(), getEvalOptions());
  }
}
