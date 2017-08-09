package haxpression2.schema;

import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;

class AnnotatedExprGroupSchema {
  public static function schema<E, V, A>(valueSchema: Schema<E, V>, annotationSchema: Schema<E, A>) : Schema<E, AnnotatedExprGroup<V, A>> {
    return dict(AnnotatedExprSchema.schema(valueSchema, annotationSchema));
  }
}
