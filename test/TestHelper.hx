import thx.Either;
import thx.Nel;
import thx.Validation;
import thx.Validation.*;

import Parsihax;

import utest.Assert;

using haxpression2.AnnotatedExpr;
using haxpression2.Expr;
using haxpression2.Value;
import haxpression2.eval.EvalError;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseMeta;
using haxpression2.render.ExprRenderer;
using haxpression2.render.ValueRenderer;
using haxpression2.simple.SimpleExpr;
using haxpression2.simple.SimpleValue;

class TestHelper {
  public static function getTestParserOptions() : SimpleParserOptions {
    return {
      variableNameRegexp: ~/[a-z][a-z0-9]*(?:!?[a-z0-9]+)?/i,
      functionNameRegexp: ~/[a-z]+/i,
      binOps: SimpleExprs.getStandardBinOps(),
      unOps: SimpleExprs.getStandardUnOps(),
      parseDecimal: Std.parseFloat,
      convertValue: thx.Functions.identity,
      annotate: ParseMeta.new
    };
  }

  public static function getTestEvalOptions() : SimpleEvalOptions {
    return {
      variables: [
        "a" => Values.int(0),
        "b" => Values.int(1),
        "c" => Values.int(2),
        "x" => Values.int(10),
        "y" => Values.int(-10),
        "z" => Values.int(100)
      ],
      unOps: SimpleExprs.getStandardEvalUnOps(),
      binOps: SimpleExprs.getStandardEvalBinOps(),
      functions: SimpleExprs.getStandardEvalFunctions(),
      onError: (error, expr) -> new EvalError(error, expr)
    };
  }

  public static function getTestExprParser() : Parser<SimpleAnnotatedExpr> {
    return ExprParser.create(getTestParserOptions()).expr;
  }

  public static function testParseString(input : String) : Either<SimpleParseError, SimpleAnnotatedExpr> {
    return SimpleExprs.parseString(input, getTestParserOptions());
  }

  public static function assertParseString(input : String, expected : SimpleAnnotatedExpr, ?log : Bool, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parseString(input, TestHelper.getTestParserOptions()) {
      case Left(parseError) : Assert.fail(parseError.toString(), pos);
      case Right(actual) :
        if (log) {
          trace(input);
          trace(actual.renderString(v -> v.renderString(), meta -> meta.toString()));
        }
        Assert.same(expected, actual, pos);
    }
  }

  public static function assertParseError(input : String, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parseString(input, TestHelper.getTestParserOptions()) {
      case Left(parseError) : Assert.pass(pos);
      case Right(_) : Assert.fail('$input should not have parsed', pos);
    };
  }

  public static function assertFormatString(expected : String, input : String, ?pos : haxe.PosInfos) : Void {
    switch SimpleExprs.formatString(input, getTestParserOptions()) {
      case Left(error) : Assert.fail(error.toString());
      case Right(actual) : Assert.same(expected, actual);
    };
  }

  static function evalErrorsToString(errors : Nel<{ expr: SimpleAnnotatedExpr, error: SimpleEvalError }>) : String {
    return errors.map(evalErrorToString).toArray().join("\n");
  }

  static function evalErrorToString(data: { expr: SimpleAnnotatedExpr, error : SimpleEvalError }) : String {
    return data.error.getString(ae -> ae.renderString(SimpleValues.renderString, meta -> meta.toString()));
  }

  public static function testEvalString(input : String) : VNel<String, SimpleValue> {
    return switch SimpleExprs.evalString(input, getTestParserOptions(), getTestEvalOptions()) {
      case ParseError(error) : failureNel(error.toString());
      case EvalErrors(errors) : failureNel(evalErrorsToString(errors));
      case Success(value) : successNel(value);
    };
  }

  public static function assertEvalString(expected : SimpleValue, input : String, ?pos : haxe.PosInfos) : Void {
    switch testEvalString(input) {
      case Left(errors) : Assert.fail(errors.toArray().map(err -> err.toString()).join("\n"), pos);
      case Right(actual) : Assert.same(expected, actual, pos);
    };
  }

  public static function traceExpr(input : String, ?pos : haxe.PosInfos) : Void {
    switch testParseString(input) {
      case Left(error) : trace(error.toString(), pos);
      case Right(value) : trace(value.renderString(SimpleValues.renderString, a -> a.toString()), pos);
    };
  }

  public static function assertExprGetVars(expected : Array<String>, input : String, ?pos : haxe.PosInfos) : Void {
    switch testParseString(input) {
      case Left(error) : trace(error.toString(), pos);
      case Right(ae) : Assert.same(expected, Exprs.getVars(ae.expr), pos);
    }
  }

  public static function assertAnnotatedExprGetVars(expected : Map<String, Array<ParseMeta>>, input : String, ?pos : haxe.PosInfos) : Void {
    switch testParseString(input) {
      case Left(error) : trace(error.toString(), pos);
      case Right(ae) : Assert.same(expected, AnnotatedExpr.getVars(ae), pos);
    }
  }
}
