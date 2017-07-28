package haxpression2;

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
using haxpression2.Value;

class TestHelper {
  public static function getTestParserOptions() : ExprParserOptions<Value<Float>, Float, ParseMeta> {
    return {
      variableNameRegexp: ~/[a-z][a-z0-9]*(?:!?[a-z0-9]+)?/i,
      functionNameRegexp: ~/[a-z]+/i,
      binOps: BinOp.getStandardBinOps(),
      unOps: UnOp.getStandardUnOps(),
      convertFloat: thx.Functions.identity,
      convertValue: thx.Functions.identity,
      annotate: ParseMeta.new
    };
  }

  public static function getTestEvalOptions() : EvalOptions<Value<Float>> {
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
      unOps: {
        pre: [
          "-" => FloatExpr.negate,
          //"++" => FloatExpr.increment,
          //"!" => FloatExpr.not,
          "~" => FloatExpr.not
        ],
        post: new Map()
      },
      binOps: [
        "+" => FloatExpr.add,
        "-" => FloatExpr.sub,
        "*" => FloatExpr.mul,
        "/" => FloatExpr.div,
        "||" => FloatExpr.or,
        "&&" => FloatExpr.and
      ]
    };
  }

  public static function getTestExprParser() : Parser<FloatAnnotatedExpr> {
    return ExprParser.create(getTestParserOptions()).expr;
  }

  public static function parse(input : String) : Either<ParseError<AnnotatedExpr<Value<Float>, ParseMeta>>, AnnotatedExpr<Value<Float>, ParseMeta>> {
    return FloatExpr.parse(input, getTestParserOptions());
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

/*
  function assertLit(input : String, expected : Expr<Value<Float>, ParseMeta>, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parse(input, getOptions()) {
      case Left(parseError) : Assert.fail(parseError.toString(), pos);
      case Right(actual) : Assert.same(expected, actual);
    };
  }

  function assertVar(input : String, name : String, meta : ParseMeta, ?pos : haxe.PosInfos) : Void {
    assertExpr(input, EVar(name, meta), pos);
  }
  */

  public static function assertParseError(input : String, ?pos : haxe.PosInfos) : Void {
    switch ExprParser.parse(input, TestHelper.getTestParserOptions()) {
      case Left(parseError) : Assert.pass(pos);
      case Right(_) : Assert.fail('$input should not have parsed', pos);
    };
  }

  public static function assertRoundTrip(expected : String, input : String, ?pos : haxe.PosInfos) : Void {
    switch FloatExpr.roundTrip(input, getTestParserOptions()) {
      case Left(error) : Assert.fail(error.toString());
      case Right(actual) : Assert.same(expected, actual);
    };
  }

  public static function eval(input : String) : VNel<String, Value<Float>> {
    return FloatExpr.eval(input, getTestParserOptions(), getTestEvalOptions());
  }

  public static function assertEval(expected : Value<Float>, input : String, ?pos : haxe.PosInfos) : Void {
    switch eval(input) {
      case Left(errors) : Assert.fail(errors.toArray().map(err -> err.toString()).join("\n"), pos);
      case Right(actual) : Assert.same(expected, actual, pos);
    };
  }

  public static function traceExpr(input : String, ?pos : haxe.PosInfos) : Void {
    switch parse(input) {
      case Left(error) : trace(error.toString(), pos);
      case Right(value) : trace(value.toString(FloatExpr.valueToString, a -> a.toString()), pos);
    };
  }
}
