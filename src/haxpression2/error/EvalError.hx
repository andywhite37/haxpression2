package haxpression2.error;

import haxe.PosInfos;
import haxe.CallStack;

import thx.Error;

import Parsihax;

class EvalError<Expr> extends Error {
  public var expr(default, null) : Expr;

  public function new(message: String, expr : Expr, ?stack: Array<StackItem>, ?pos: PosInfos) {
    super(message, stack, pos);
    this.expr = expr;
  }

  public function getString(exprToString : Expr -> String) : String {
    return '$message in expression: ${exprToString(expr)}';
  }
}

