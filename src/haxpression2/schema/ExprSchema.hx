package haxpression2.schema;

import thx.Validation;
import thx.schema.ParseError;
import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;
using thx.schema.SchemaDynamicExtensions;

import haxpression2.Expr;

class ExprSchema {
  public static function schema<E, V, A>(valueSchema : Schema<E, V>, annotationSchema : Schema<E, A>) : Schema<E, Expr<V, A>> {
    var annotatedExprSchema = AnnotatedExprSchema.schema(valueSchema, annotationSchema);
    return oneOf([
      alt(
        "EVar",
        string(),
        (name: String) -> EVar(name),
        (expr : Expr<V, A>) -> switch expr {
          case EVar(name) : Some(name);
          case _ : None;
        }
      ),
      alt(
        "ELit",
        valueSchema,
        (value: V) -> ELit(value),
        (expr : Expr<V, A>) -> switch expr {
          case ELit(value) : Some(value);
          case _ : None;
        }
      ),
      alt(
        "EFunc",
        object(ap2(
          (name : String, args : Array<AnnotatedExpr<V, A>>) -> { name: name, args: args },
          required("name", string(), (obj : { name: String, args: Array<AnnotatedExpr<V, A>> }) -> obj.name),
          required("args", array(annotatedExprSchema), (obj : { name: String, args: Array<AnnotatedExpr<V, A>> }) -> obj.args)
        )),
        (obj : { name : String, args: Array<AnnotatedExpr<V, A>> }) -> EFunc(obj.name, obj.args),
        (expr : Expr<V, A>) -> switch expr {
          case EFunc(name, args) : Some({ name: name, args: args });
          case _ : None;
        }
      ),
      alt(
        "EBinOp",
        object(ap4(
          (operator : String, precedence: Int, left : AnnotatedExpr<V, A>, right : AnnotatedExpr<V, A>) -> { operator: operator, precedence: precedence, left: left, right: right },
          required("operator", string(), (obj : { operator: String, precedence: Int, left: AnnotatedExpr<V, A>, right: AnnotatedExpr<V, A> }) -> obj.operator),
          required("precedence", int(), (obj : { operator: String, precedence: Int, left: AnnotatedExpr<V, A>, right: AnnotatedExpr<V, A> }) -> obj.precedence),
          required("left", annotatedExprSchema, (obj : { operator: String, precedence: Int, left: AnnotatedExpr<V, A>, right: AnnotatedExpr<V, A> }) -> obj.left),
          required("right", annotatedExprSchema, (obj : { operator: String, precedence: Int, left: AnnotatedExpr<V, A>, right: AnnotatedExpr<V, A> }) -> obj.right)
        )),
        (obj : { operator: String, precedence: Int, left: AnnotatedExpr<V, A>, right: AnnotatedExpr<V, A> }) -> EBinOp(obj.operator, obj.precedence, obj.left, obj.right),
        (expr : Expr<V, A>) -> switch expr {
          case EBinOp(op, prec, left, right) : Some({ operator: op, precedence: prec, left: left, right: right });
          case _ : None;
        }
      ),
      alt(
        "EUnOpPre",
        object(ap3(
          (operator : String, precedence : Int, operand : AnnotatedExpr<V, A>) -> { operator: operator, precedence: precedence, operand: operand },
          required("operator", string(), (obj : { operator: String, precedence: Int, operand: AnnotatedExpr<V, A> }) -> obj.operator),
          required("precedence", int(), (obj : { operator: String, precedence: Int, operand: AnnotatedExpr<V, A> }) -> obj.precedence),
          required("operand", annotatedExprSchema, (obj : { operator: String, precedence: Int, operand: AnnotatedExpr<V, A> }) -> obj.operand)
        )),
        (obj : { operator: String, precedence: Int, operand: AnnotatedExpr<V, A> }) -> EUnOpPre(obj.operator, obj.precedence, obj.operand),
        (expr : Expr<V, A>) -> switch expr {
          case EUnOpPre(op, prec, opnd) : Some({ operator: op, precedence: prec, operand: opnd });
          case _ : None;
        }
      )
    ]);
  }
}
