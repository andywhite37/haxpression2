package haxpression2.compile;

import utest.Assert;

import haxpression2.compile.ExprCompiler;
import haxpression2.parse.ParseMeta;
import haxpression2.parse.ParseMeta.create as meta;

class TestExprCompiler {
  public function new() {}

  public function testCompile_Success1() {
    var result = ExprCompiler.parseAndCompile(
      "1 + CAGR(asn!SALES, '5Y')",
      TestHelper.getTestExprParserOptions({ annotate: ParseMeta.new }),
      ExprCompiler.getSimpleExprCompilerOptions()
    );

    switch result {
      case ParseError(error) : Assert.fail(error.toString());
      case CompileErrors(errors) : Assert.fail(errors.toArray().map(e -> e.toString()).join("\n"));
      case Compiled(acec) :
        Assert.same(
          CE(
            DTNum,
            new AnnotatedCompiledExpr(
              CENumBinOp(
                Add(
                  new AnnotatedCompiledExpr(
                    CELit(DTNum, Val(1.0)),
                    meta(0, 1, 1)
                  ),
                  new AnnotatedCompiledExpr(
                    CEFunc(
                      CAGR(
                        new AnnotatedCompiledExpr(
                          CEVar(DTNum, "asn!SALES"),
                          meta(9, 1, 10)
                        ),
                        new AnnotatedCompiledExpr(
                          CELit(DTSpan, Span(5, Year)),
                          meta(20, 1, 21)
                        )
                      )
                    ),
                    meta(4, 1, 5)
                  )
                )
              ),
              meta(2, 1, 3)
            )
          ),
          acec
        );
    };
  }

  public function testCompile_Success2() : Void {
    var result = ExprCompiler.parseAndCompile(
      "COALESCE(NA, 2, NM)",
      TestHelper.getTestExprParserOptions({ annotate: ParseMeta.new }),
      ExprCompiler.getSimpleExprCompilerOptions()
    );
    return switch result {
      case ParseError(_) : Assert.fail('should not have failed to parse');
      case CompileErrors(_) : Assert.fail('should not have failed to compile');
      case Compiled(acec) :
        Assert.same(
          CE(
            DTNum,
            new AnnotatedCompiledExpr(
              CEFunc(
                Coalesce([
                  new AnnotatedCompiledExpr(
                    CELit(DTNum, NA),
                    meta(9, 1, 10)
                  ),
                  new AnnotatedCompiledExpr(
                    CELit(DTNum, Val(2)),
                    meta(13, 1, 14)
                  ),
                  new AnnotatedCompiledExpr(
                    CELit(DTNum, NM),
                    meta(16, 1, 17)
                  )
                ])
              ),
              meta(0, 1, 1)
            )
          ),
          acec
        );
    };
    trace(result);
  }

  public function testCompile_Error1() : Void {
    var result = ExprCompiler.parseAndCompile(
      "COALESCE(1, true, 'hi')",
      TestHelper.getTestExprParserOptions({ annotate: ParseMeta.new }),
      ExprCompiler.getSimpleExprCompilerOptions()
    );
    switch result {
      case ParseError(error) : Assert.fail('expression should have parsed');
      case CompileErrors(errorsNel) :
        var errors = errorsNel.toArray().reverse().map(e -> e.toString());
        Assert.same(2, errors.length);
        Assert.same('Expected a number expression, but found a boolean expression (position: 12)', errors[0]);
        Assert.same('Expected a number expression, but found a string expression (position: 18)', errors[1]);
      case Compiled(_) : Assert.fail('expression should not have compiled');
    }
  }
}
