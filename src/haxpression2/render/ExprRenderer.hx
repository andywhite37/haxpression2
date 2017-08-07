package haxpression2.render;

import thx.Either;
using thx.Eithers;
using thx.Strings;

import haxpression2.Expr;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;

class ExprRenderer {
  public static function render<V, A>(expr : Expr<V, A>, valueToString : V -> String) : String {
    return switch expr {
      case ELit(value) : valueToString(value);

      case EVar(name) : name;

      case EFunc(name, argExprs) :
        var argsStr = argExprs.map(argExpr -> render(argExpr.expr, valueToString)).join(", ");
        '${name}(${argsStr})';

      case EUnOpPre(operator, precedence, operandExpr) :
        '${operator}${render(operandExpr.expr, valueToString)}';

      case EBinOp(operator, precedence, leftExpr, rightExpr) :
        var leftStr = render(leftExpr.expr, valueToString);
        var leftStrSafe = switch leftExpr.expr {
          case EBinOp(_, lprecedence, _, _) if (lprecedence < precedence) :
            // if a left-side bin op has lower precendence, parenthesize it
            '($leftStr)';
          case _ :
            '$leftStr';
        };
        var rightStr = render(rightExpr.expr, valueToString);
        var rightStrSafe = switch rightExpr.expr {
          case EBinOp(_, rprecedence, _, _) if (rprecedence < precedence) :
            // if a right-side bin op has lower precendence, parenthesize it
            '($rightStr)';
          case _ :
            '$rightStr';
        };
        '$leftStrSafe $operator $rightStrSafe';
    }
  }

  public static function format<V, D, A>(input : String, parserOptions : ExprParserOptions<V, D, A>, valueToString : V -> String) : Either<ParseError<AnnotatedExpr<V, A>>, String> {
    return ExprParser.parse(input, parserOptions).map(ae -> render(ae.expr, valueToString));
  }
}

class AnnotatedExprRenderer {
  public static function render<V, A>(ae : AnnotatedExpr<V, A>, valueToString : V -> String, annotationToString : A -> String, ?depth = 0) : String {
    var indent = "  ".repeat(depth);
    return switch ae.expr {
      case e = ELit(v) :
        '${ExprRenderer.render(e, valueToString)} ${annotationToString(ae.annotation)}';

      case e = EVar(name) :
        '${ExprRenderer.render(e, valueToString)} ${annotationToString(ae.annotation)}';

      case e = EFunc(name, argExprs) :
        var argStrings = argExprs.map(argExpr -> render(argExpr, valueToString, annotationToString, depth + 1)).join('\n$indent');
'${ExprRenderer.render(e, valueToString)}
$argStrings';

      case e = EUnOpPre(operator, precendece, operandExpr) :
        var operandString = render(operandExpr, valueToString, annotationToString, depth + 1);
'${ExprRenderer.render(e, valueToString)}
${indent}${operator} ${annotationToString(ae.annotation)}
${indent}  Operand: $operandString';

      case e = EBinOp(op, prec, left, right) :
        var leftString = render(left, valueToString, annotationToString, depth + 1);
        var rightString = render(right, valueToString, annotationToString, depth + 1);
'${ExprRenderer.render(e, valueToString)}
${indent}${op} (prec: ${prec}) ${annotationToString(ae.annotation)}
${indent}  Left: $leftString
${indent}  Right: $rightString';
    };
  }

}
