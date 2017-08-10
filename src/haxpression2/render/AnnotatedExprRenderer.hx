package haxpression2.render;

import thx.Either;
using thx.Eithers;
using thx.Strings;

using thx.schema.SchemaDynamicExtensions;
using thx.schema.SimpleSchema;

import haxpression2.Expr;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
using haxpression2.render.SchemaJSONRenderer;
import haxpression2.schema.AnnotatedExprSchema;

class AnnotatedExprRenderer {
  public static function renderJSONString<E, V, A>(ae : AnnotatedExpr<V, A>, valueSchema : Schema<E, V>, annotationSchema : Schema<E, A>) : String {
    return AnnotatedExprSchema.schema(valueSchema, annotationSchema).renderJSONString(ae);
  }
}
