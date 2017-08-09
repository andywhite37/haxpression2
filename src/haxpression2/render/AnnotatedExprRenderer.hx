package haxpression2.render;

import thx.Either;
using thx.Eithers;
using thx.Strings;

using thx.schema.SchemaDynamicExtensions;
using thx.schema.SimpleSchema;

import haxpression2.Expr;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
using haxpression2.render.JSONRenderer;
import haxpression2.schema.AnnotatedExprSchema;

class AnnotatedExprRenderer {
  /*
  public static function renderString<V, A>(ae : AnnotatedExpr<V, A>, valueToString : V -> String, annotationToString : A -> String, ?depth = 0) : String {
    var indent = "  ".repeat(depth);
    return switch ae.expr {
      case e = ELit(v) :
'expr: ${ExprRenderer.renderString(e, valueToString)}
annotataion: ${annotationToString(ae.annotation)}';

      case e = EVar(name) :
'expr: ${ExprRenderer.renderString(e, valueToString)}
annotation: ${annotationToString(ae.annotation)}';

      case e = EFunc(name, argExprs) :
        var argStrings = argExprs.map(argExpr -> renderString(argExpr, valueToString, annotationToString, depth + 1)).join('\n$indent');
'expr: ${ExprRenderer.renderString(e, valueToString)}
annotation: $argStrings';

      case e = EUnOpPre(operator, precedence, operandExpr) :
        var operandString = renderString(operandExpr, valueToString, annotationToString, depth + 1);
'expr: ${ExprRenderer.renderString(e, valueToString)}
annotation: ${annotationToString(ae.annotation)}
${indent}operator: ${operator}\n
${indent}precendence: ${precedence}\n
${indent}  operand:\n$operandString';

      case e = EBinOp(operator, precedence, left, right) :
        var leftString = renderString(left, valueToString, annotationToString, depth + 1);
        var rightString = renderString(right, valueToString, annotationToString, depth + 1);
'expr: ${ExprRenderer.renderString(e, valueToString)}
annotation: ${annotationToString(ae.annotation)}
${indent}operator: ${operator}
${indent}precendence: ${precedence}
${indent}  left:\n$leftString
${indent}  right:\n$rightString';
    };
  }
  */

  public static function renderJSONString<E, V, A>(ae : AnnotatedExpr<V, A>, valueSchema : Schema<E, V>, annotationSchema : Schema<E, A>) : String {
    return AnnotatedExprSchema.schema(valueSchema, annotationSchema).renderJSONString(ae);
  }
}
