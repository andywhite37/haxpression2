package haxpression2.render;

import TestHelper.assertParseRender;

class TestExprRenderer {
  public function new() {}

  public function testParseRender() {
    assertParseRender("1 + 2 + 3", "1 + 2 + 3");
    assertParseRender("1 + 2 + 3", "1 + (2 + 3)");
    assertParseRender("1 + 2 + 3", "(1 + (2) + 3)");
    assertParseRender("1 + 2 + 3", "((1 + 2) + 3)");
    assertParseRender("1 * 2 + 3", "1 * 2 + 3");
    assertParseRender("1 * (2 + 3)", "(1 * (2 + 3))");
    assertParseRender("1 + 2 - 3 * 4 / 5", "1+2-3*4/5");
    assertParseRender("1 / 2 * 3 - 4 + 5", "1/2*3-4+5");
    assertParseRender("1 + 2 * 3 - 4", "1 + 2 * 3 - 4");
    assertParseRender("1 * 2 + 3 * 4", "1 * 2 + 3 * 4");
    assertParseRender("1 * 2 + 3 * 4", "1 * 2 + 3 * 4");
    assertParseRender("(1 + 2) * (3 - 4)", "( 1 + 2 ) * ( 3 - 4 )");
    assertParseRender("1 + x * myFunc(true, false, \"hi\") / sales", "1+x*myFunc ( true, false,  'hi'  ) / sales ");
    assertParseRender("1 + x * myFunc(1 * (2 + 3)) / sales", "1+x*myFunc (1 * (2 + 3)) / sales ");
  }
}
