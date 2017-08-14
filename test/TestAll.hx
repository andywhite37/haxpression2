import utest.Runner;
import utest.ui.Report;

class TestAll {
  public static function main() {
    var runner = new Runner();

    runner.addCase(new haxpression2.TestAnnotatedExpr());
    runner.addCase(new haxpression2.TestAnnotatedExprGroup());
    runner.addCase(new haxpression2.TestExpr());
    runner.addCase(new haxpression2.compile.TestExprCompiler());
    runner.addCase(new haxpression2.eval.TestExprEvaluator());
    runner.addCase(new haxpression2.parse.TestExprParser());
    runner.addCase(new haxpression2.parse.TestValueParser());
    runner.addCase(new haxpression2.render.TestExprRenderer());
    runner.addCase(new haxpression2.schema.TestAnnotatedExprSchema());
    runner.addCase(new haxpression2.schema.TestExprSchema());
    runner.addCase(new haxpression2.schema.TestValueSchema());

#if js
    //runner.addCase(new mappings.TestMappings());
#end

    Report.create(runner);
    runner.run();
  }
}
