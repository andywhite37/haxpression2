package haxpression2;

using thx.Arrays;
using thx.Eithers;
using thx.Maps;
import thx.Nel;
import thx.Tuple;
import thx.Validation;
import thx.Validation.*;

import haxpression2.AnnotatedExpr;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
import haxpression2.render.ExprRenderer;

typedef AnnotatedExprGroupImpl<V, A> = Map<String, AnnotatedExpr<V, A>>;

abstract AnnotatedExprGroup<V, A>(AnnotatedExprGroupImpl<V, A>) from AnnotatedExprGroupImpl<V, A> to AnnotatedExprGroupImpl<V, A> {
  public function new(value : AnnotatedExprGroupImpl<V, A>) {
    this = value;
  }

  public static function parseStringToStringMap<V, N, A>(
    map : Map<String, String>,
    parserOptions: ExprParserOptions<V, N, A>
  ) : VNel<ParseError<AnnotatedExpr<V, A>>, AnnotatedExprGroup<V, A>> {
    return map.tuples().traverseValidation(function(keyValue : Tuple<String, String>) {
      // Parse each expression in the input map
      var key : String = keyValue._0;
      var exprString : String = keyValue._1;
      return ExprParser.parseString(exprString, parserOptions).map(expr -> Tuple.of(key, expr)).toVNel();
    }, Nel.semigroup())
    .map(function(tuples : Array<Tuple<String, AnnotatedExpr<V, A>>>) {
      // Convert Array<Tuple> back to a Map
      return tuples.reduce(function(acc : AnnotatedExprGroup<V, A>, tuple : Tuple<String, AnnotatedExpr<V, A>>) {
        return acc.set(tuple._0, tuple._1);
      }, new AnnotatedExprGroup(new Map()));
    });
  }

  public static function parseStringToFallbackStringsMap<V, N, A>(
    fallbackMap : Map<String, Array<String>>,
    parserOptions: ExprParserOptions<V, N, A>
  ) : VNel<ParseError<AnnotatedExpr<V, A>>, AnnotatedExprGroup<V, A>> {
    var coalesceMap : Map<String, String> = fallbackMap.mapValues(function(exprStrings : Array<String>) : String {
      return 'COALESCE(${exprStrings.join(", ")})';
    }, new Map());
    return parseStringToStringMap(coalesceMap, parserOptions);
  }

  public function set(name : String, expr : AnnotatedExpr<V, A>) : AnnotatedExprGroup<V, A> {
    this.set(name, expr);
    return this;
  }

  public function renderString(valueToString: V -> String) : String {
    return this.foldLeftWithKeys(function(acc : Array<String>, key : String, value: AnnotatedExpr<V, A>) : Array<String> {
      return acc.append('$key: ${ExprRenderer.renderString(value.expr, valueToString)}');
    }, [])
    .join("\n");
  }
}
