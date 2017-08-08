package haxpression2.schema;

import thx.Unit;
import thx.schema.SchemaF;
import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;

class AnnotatedExprSchema {
  public static function schema<E, V, A>(valueSchema : Schema<E, V>, annotationSchema: Schema<E, A>) : Schema<E, AnnotatedExpr<V, A>> {
    return object(ap2(
      AnnotatedExpr.new,
      // Expr schema is lazy here because there is a circular reference between Expr and AnnotatedExpr
      required("expr", lazy(() -> ExprSchema.schema(valueSchema, annotationSchema).schema), (ae : AnnotatedExpr<V, A>) -> ae.expr),
      required("annotation", annotationSchema, (ae : AnnotatedExpr<V, A>) -> ae.annotation)
    ));
  }
}
