import utest.Runner;
import utest.ui.Report;

class TestAll {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new haxpression2.TestExpr());
    runner.addCase(new haxpression2.TestExprParser());
    runner.addCase(new haxpression2.TestParseError());
    runner.addCase(new haxpression2.TestValue());
    runner.addCase(new haxpression2.TestValueParser());
    Report.create(runner);
    runner.run();
  }
}
