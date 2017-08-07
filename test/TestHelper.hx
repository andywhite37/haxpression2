using thx.Arrays;
import thx.Either;
using thx.Eithers;
import thx.Validation;
import thx.Validation.*;

import Parsihax;

import utest.Assert;

import haxpression2.BinOp;
using haxpression2.Expr;
import haxpression2.ExprParser;
import haxpression2.FloatExpr;
import haxpression2.ParseMeta;
import haxpression2.UnOp;
using haxpression2.Value;
import haxpression2.error.EvalError;
import haxpression2.error.ParseError;

class TestHelper {
  public static function getTestParserOptions() : FloatParserOptions {
    return {
      variableNameRegexp: ~/[a-z][a-z0-9]*(?:!?[a-z0-9]+)?/i,
      functionNameRegexp: ~/[a-z]+/i,
      binOps: FloatExprs.getStandardBinOps(),
      unOps: FloatExprs.getStandardUnOps(),
      parseDecimal: Std.parseFloat,
      convertValue: thx.Functions.identity,
      annotate: ParseMeta.new
    };
  }

  public static function getTestEvalOptions() : FloatEvalOptions {
    return {
      variables: [
        "a" => Values.int(0),
        "b" => Values.int(1),
        "c" => Values.int(2),
        "x" => Values.int(10),
        "y" => Values.int(-10),
        "z" => Values.int(100)
      ],
      unOps: FloatExprs.getStandardEvalUnOps(),
      binOps: FloatExprs.getStandardEvalBinOps(),
      functions: FloatExprs.getStandardEvalFunctions(),
      onError: (error, expr) -> new EvalError(error, expr)
    };
  }

  public static function getTestExprParser() : Parser<FloatAnnotatedExpr> {
    return ExprParser.create(getTestParserOptions()).expr;
  }

  public static function testParse(input : String) : Either<ParseError<AnnotatedExpr<Value<Float>, ParseMeta>>, AnnotatedExpr<Value<Float>, ParseMeta>> {
    return FloatExprs.parse(input, getTestParserOptions());
  }

  public static function assertParse(input : String, expected : AnnotatedExpr<Value<Float>, ParseMeta>, ?log : Bool, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parse(input, TestHelper.getTestParserOptions()) {
      case Left(parseError) : Assert.fail(parseError.toString(), pos);
      case Right(actual) :
        if (log) {
          trace(input);
          trace(actual.toString(v -> Values.toString(v, Std.string), a -> a.toString()));
        }
        Assert.same(expected, actual, pos);
    }
  }

  public static function assertParseError(input : String, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parse(input, TestHelper.getTestParserOptions()) {
      case Left(parseError) : Assert.pass(pos);
      case Right(_) : Assert.fail('$input should not have parsed', pos);
    };
  }

  public static function assertRoundTrip(expected : String, input : String, ?pos : haxe.PosInfos) : Void {
    switch FloatExprs.roundTrip(input, getTestParserOptions()) {
      case Left(error) : Assert.fail(error.toString());
      case Right(actual) : Assert.same(expected, actual);
    };
  }

  public static function testParseEval(input : String) : VNel<String, Value<Float>> {
    return switch FloatExprs.parseEval(input, getTestParserOptions(), getTestEvalOptions()) {
      case ParseError(error) : failureNel(error.toString());
      case EvalError(exprErrors) : failure(exprErrors.map(exprError -> exprError.error.toString()));
      case Success(value) : successNel(value);
    };
  }

  public static function assertParseEval(expected : Value<Float>, input : String, ?pos : haxe.PosInfos) : Void {
    switch testParseEval(input) {
      case Left(errors) : Assert.fail(errors.toArray().map(err -> err.toString()).join("\n"), pos);
      case Right(actual) : Assert.same(expected, actual, pos);
    };
  }

  public static function traceExpr(input : String, ?pos : haxe.PosInfos) : Void {
    switch testParse(input) {
      case Left(error) : trace(error.toString(), pos);
      case Right(value) : trace(value.toString(FloatExprs.valueToString, a -> a.toString()), pos);
    };
  }
}
