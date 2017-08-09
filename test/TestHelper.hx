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
import haxpression2.schema.ParseMetaSchema;
import haxpression2.simple.SimpleExpr;
import haxpression2.simple.SimpleValue;

class TestHelper {
  public static function getTestParserOptions() : SimpleParserOptions {
    return SimpleExprs.getStandardParserOptions();
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

  public static function assertParseValue(expected : SimpleValue, input : String, ?pos : haxe.PosInfos) : Void {
    switch SimpleValueParser.parseString(input) {
      case Left(error) : Assert.fail(error.toString(), pos);
      case Right(actual) : Assert.same(expected, actual);
    };
  }

  public static function assertParseValueError(input : String, ?pos : haxe.PosInfos) : Void {
    switch SimpleValueParser.parseString(input) {
      case Left(errors) : Assert.pass(pos);
      case Right(actual) : Assert.fail('$input should not have parsed as a value', pos);
    };
  }

  public static function parseString(input : String) : Either<SimpleParseError, SimpleAnnotatedExpr> {
    return SimpleExprParser.parseString(input, getTestParserOptions());
  }

  public static function parseStrings(input : Array<String>) : VNel<SimpleParseError, Array<SimpleAnnotatedExpr>> {
    return SimpleExprParser.parseStrings(input, getTestParserOptions());
  }

  public static function parseStringMap(input : Map<String, String>) : VNel<SimpleParseError, Map<String, SimpleAnnotatedExpr>> {
    return SimpleExprParser.parseStringMap(input, getTestParserOptions());
  }

  public static function renderString(input : SimpleExpr) : String {
    return SimpleExprRenderer.renderString(input);
  }

  public static function assertParseString(input : String, expected : SimpleAnnotatedExpr, ?log : Bool, ?pos : haxe.PosInfos) : Void {
    switch SimpleExprParser.parseString(input, TestHelper.getTestParserOptions()) {
      case Left(parseError) : Assert.fail(parseError.toString(), pos);
      case Right(actual) :
        if (log) {
          trace(input);
          trace(SimpleAnnotatedExprRenderer.renderJSONString(actual, SimpleValueSchema.schema(), ParseMetaSchema.schema()));
        }
        Assert.same(expected, actual, pos);
    }
  }

  public static function assertParseStringError(input : String, ?pos : haxe.PosInfos) : Void {
    switch SimpleExprParser.parseString(input, TestHelper.getTestParserOptions()) {
      case Left(parseError) : Assert.pass(pos);
      case Right(_) : Assert.fail('$input should not have parsed', pos);
    };
  }

  public static function assertFormatString(expected : String, input : String, ?pos : haxe.PosInfos) : Void {
    switch SimpleExprRenderer.formatString(input, getTestParserOptions()) {
      case Left(error) : Assert.fail(error.toString());
      case Right(actual) : Assert.same(expected, actual);
    };
  }

  static function evalErrorsToString(errors : Nel<{ expr: SimpleAnnotatedExpr, error: SimpleEvalError }>) : String {
    return errors.map(evalErrorToString).toArray().join("\n");
  }

  static function evalErrorToString(data: { expr: SimpleAnnotatedExpr, error : SimpleEvalError }) : String {
    return data.error.getString(ae -> SimpleAnnotatedExprRenderer.renderJSONString(ae, SimpleValueSchema.schema(), ParseMetaSchema.schema()));
  }

  public static function evalString(input : String) : VNel<String, SimpleValue> {
    return switch SimpleAnnotatedExprEvaluator.evalString(input, getTestParserOptions(), getTestEvalOptions()) {
      case ParseError(error) : failureNel(error.toString());
      case EvalErrors(errors) : failureNel(evalErrorsToString(errors));
      case Success(value) : successNel(value);
    };
  }

  public static function assertEvalString(expected : SimpleValue, input : String, ?pos : haxe.PosInfos) : Void {
    switch evalString(input) {
      case Left(errors) : Assert.fail(errors.toArray().map(err -> err.toString()).join("\n"), pos);
      case Right(actual) : Assert.same(expected, actual, pos);
    };
  }

  public static function traceExpr(input : String, ?pos : haxe.PosInfos) : Void {
    switch parseString(input) {
      case Left(error) : trace(error.toString(), pos);
      case Right(ae) : trace(SimpleExprRenderer.renderString(ae.expr));
    };
  }

  public static function assertExprGetVars(expected : Array<String>, input : String, ?pos : haxe.PosInfos) : Void {
    switch parseString(input) {
      case Left(error) : trace(error.toString(), pos);
      case Right(ae) : Assert.same(expected, Exprs.getVars(ae.expr), pos);
    }
  }

  public static function assertAnnotatedExprGetVars(expected : Map<String, Array<ParseMeta>>, input : String, ?pos : haxe.PosInfos) : Void {
    switch parseString(input) {
      case Left(error) : trace(error.toString(), pos);
      case Right(ae) : Assert.same(expected, AnnotatedExpr.getVars(ae), pos);
    }
  }
}
