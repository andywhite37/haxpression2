package haxpression2;

import haxe.ds.Option;

using thx.Arrays;
using thx.Iterators;
using thx.Maps;
using thx.Options;
import thx.Unit;
import thx.Validation;

import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;

import graphx.StringGraph;
import graphx.NodeOrValue;

using haxpression2.AnnotatedExpr;
using haxpression2.AnnotatedExprGroup;
using haxpression2.Expr;
using haxpression2.Value;
using haxpression2.eval.AnnotatedExprEvaluator;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
import haxpression2.render.ExprRenderer;
using haxpression2.render.SchemaJSONRenderer;
import haxpression2.schema.AnnotatedExprGroupSchema;

typedef AnnotatedExprGroupImpl<V, A> = Map<String, AnnotatedExpr<V, A>>;

abstract AnnotatedExprGroup<V, A>(AnnotatedExprGroupImpl<V, A>) from AnnotatedExprGroupImpl<V, A> to AnnotatedExprGroupImpl<V, A> {
  public function new(value : AnnotatedExprGroupImpl<V, A>) {
    this = value;
  }

  public static inline function unwrap<V, A>(group : AnnotatedExprGroup<V, A>) : AnnotatedExprGroupImpl<V, A> {
    return group;
  }

  public static function parseStringMap<V, N, A>(
    map : Map<String, String>,
    parserOptions: ExprParserOptions<V, N, A>
  ) : VNel<ParseError<AnnotatedExpr<V, A>>, AnnotatedExprGroup<V, A>> {
    return ExprParser.parseStringMap(map, parserOptions).map(map -> new AnnotatedExprGroup(map));
  }

  public static function parseFallbackStringsMap<V, N, A>(
    fallbackMap : Map<String, Array<String>>,
    coalesceFunctionName: String,
    createSubKey: String -> Int -> String,
    parserOptions: ExprParserOptions<V, N, A>
  ) : VNel<ParseError<AnnotatedExpr<V, A>>, AnnotatedExprGroup<V, A>> {
    var coalesceMap : Map<String, String> = fallbackMap
      .foldLeftWithKeys(function(acc : Map<String, String>, key : String, exprStrings : Array<String>) : Map<String, String> {
        // If a field is not defined, remove it from the group
        return if (exprStrings == null || exprStrings.length == 0) {
          acc;
        } else {
          var subExprInfo = exprStrings.reducei(function(subExprInfo : { subKeys: Array<String>, map: Map<String, String> }, exprString : String, index: Int) : { subKeys: Array<String>, map: Map<String, String> } {
            var subKey = createSubKey(key, index);
            subExprInfo.subKeys.push(subKey);
            subExprInfo.map.set(subKey, exprString);
            return subExprInfo;
          }, { subKeys: [], map: acc });
          if (subExprInfo.subKeys.length > 0) {
            var mainExprString = if (subExprInfo.subKeys.length > 1) {
              '${coalesceFunctionName}(${subExprInfo.subKeys.join(", ")})';
            } else {
              subExprInfo.subKeys[0];
            }
            acc.set(key, mainExprString);
          }
          acc;
        }
      }, new Map());
    return parseStringMap(coalesceMap, parserOptions);
  }

  public static function mapAnnotation<V, A, B>(group : AnnotatedExprGroup<V, A>, f: String -> AnnotatedExpr<V, A> -> B) : AnnotatedExprGroup<V, B> {
    return group.foldLeftWithKeys(function(acc : AnnotatedExprGroup<V, B>, name : String, ae : AnnotatedExpr<V, A>) : AnnotatedExprGroup<V, B> {
      acc.setVar(name, ae.mapAnnotation(ae -> f(name, ae)));
      return acc;
    }, new Map());
  }

  public static function renderPlainString<V, A>(group : AnnotatedExprGroup<V, A>, valueToString: V -> String, metaToString : A -> String) : String {
    return group.foldLeftWithKeys(function(acc : Array<String>, key : String, ae: AnnotatedExpr<V, A>) : Array<String> {
      return acc.append('$key:\n  ${ExprRenderer.renderString(ae.expr, valueToString)}');
    }, [])
    .join("\n");
  }

  public static function renderJSONString<E, V, A>(group : AnnotatedExprGroup<V, A>, valueSchema: Schema<E, V>, annotationSchema: Schema<E, A>) : String {
    return AnnotatedExprGroupSchema.schema(valueSchema, annotationSchema).renderJSONString(group);
  }

  public static function getVars<V, A>(group : AnnotatedExprGroup<V, A>) : Iterator<String> {
    return unwrap(group).keys();
  }

  public static function getVarCount<V, A>(group : AnnotatedExprGroup<V, A>) : Int {
    return getVars(group).toArray().length;
  }

  public static function hasVar<V, A>(group : AnnotatedExprGroup<V, A>, name : String) : Bool {
    return unwrap(group).exists(name);
  }

  public static function getVar<V, A>(group : AnnotatedExprGroup<V, A>, name : String) : Option<AnnotatedExpr<V, A>> {
    return group.getOption(name);
  }

  public static function setVar<V, A>(group : AnnotatedExprGroup<V, A>, name : String, ae : AnnotatedExpr<V, A>) : AnnotatedExprGroup<V, A> {
    unwrap(group).set(name, ae);
    return group;
  }

  public static function canExpand<V, A>(group : AnnotatedExprGroup<V, A>) : Bool {
    return group.foldLeftWithKeys(function(canExpandAcc : Bool, key : String, ae : AnnotatedExpr<V, A>) : Bool {
      return canExpandAcc || canExpandAnnotatedExpr(group, ae);
    }, false);
  }

  public static function canExpandAnnotatedExpr<V, A>(group : AnnotatedExprGroup<V, A>, ae : AnnotatedExpr<V, A>) : Bool {
      return switch ae.expr {
        case ELit(_) : false;
        case EVar(name) : hasVar(group, name);
        case EFunc(_, args) : args.any(arg -> canExpandAnnotatedExpr(group, arg));
        case EBinOp(_, _, left, right) : canExpandAnnotatedExpr(group, left) || canExpandAnnotatedExpr(group, right);
        case EUnOpPre(_, _, operand) : canExpandAnnotatedExpr(group, operand);
      };
  }

  public static function expand<V, A>(group : AnnotatedExprGroup<V, A>) : AnnotatedExprGroup<V, Unit> {
    var expandedGroup = group.mapAnnotation(function(name : String, ae : AnnotatedExpr<V, A>) : Unit {
      return unit;
    });
    while (canExpand(expandedGroup)) {
      expandedGroup = expandOnce(expandedGroup);
    }
    return expandedGroup;
  }

  public static function expandOnce<V, A>(group : AnnotatedExprGroup<V, Unit>) : AnnotatedExprGroup<V, Unit> {
    return group.foldLeftWithKeys(function(group : AnnotatedExprGroup<V, Unit>, name : String, ae : AnnotatedExpr<V, Unit>) {
      return group.setVar(name, expandAnnotatedExpr(group, ae));
    }, group);
  }

  public static function expandAnnotatedExpr<V, A>(
    group : AnnotatedExprGroup<V, Unit>,
    ae : AnnotatedExpr<V, Unit>
  ) : AnnotatedExpr<V, Unit> {
    return switch ae.expr {
      case ELit(_) : ae;
      case EVar(name) :
        group.getVar(name).cataf(
          () -> ae,
          exprForName -> ae.substitute(name, exprForName)
        );
      case EFunc(name, args) :
        var expanded : Expr<V, Unit> = EFunc(name, args.map(arg -> expandAnnotatedExpr(group, arg)));
        new AnnotatedExpr(expanded, unit);
      case EBinOp(op, prec, left, right) :
        var expanded = EBinOp(op, prec, expandAnnotatedExpr(group, left), expandAnnotatedExpr(group, right));
        new AnnotatedExpr(expanded, unit);
      case EUnOpPre(op, prec, operand) :
        var expanded = EUnOpPre(op, prec, expandAnnotatedExpr(group, operand));
        new AnnotatedExpr(expanded, unit);
    };
  }

  public static function analyze<V, A>(group : AnnotatedExprGroup<V, A>, renderValue : V -> String) : AnalyzeResult<V, A> {
    // Fully expand the group expressions
    var expandedGroup : AnnotatedExprGroup<V, Unit> = expand(group);

    // - Loop over all the variables in the group, and create a data structure to hold
    //   the original expression info and the expanded expression info.
    // - Also collect all the external variables from each variable's expression, so we can dependency sort
    //   the variables after this.
    var result : { allExternalVars: Array<String>, analyzedExprs: Map<String, AnalyzedExpr<V, A>> } =
      group.foldLeftWithKeys(function(acc : { allExternalVars: Array<String>, analyzedExprs: Map<String, AnalyzedExpr<V, A>> }, name : String, original : AnnotatedExpr<V, A>) {
        var expandedExpr = expandedGroup.unwrap().get(name);
        var expandedVars = expandedExpr.getVarsArray();
        var analyzedExpr : AnalyzedExpr<V, A> = new AnalyzedExpr({
          originalExpr: original,
          originalExprString: ExprRenderer.renderString(original.expr, renderValue),
          originalVars: original.getVarsArray(),
          expandedExpr: expandedExpr,
          expandedExprString: ExprRenderer.renderString(expandedExpr.expr, renderValue),
          expandedVars: expandedVars
        });
        acc.analyzedExprs.set(name, analyzedExpr);
        acc.allExternalVars = acc.allExternalVars.concat(expandedVars);
        return acc;
      }, { allExternalVars: [], analyzedExprs: new Map() });

    var definedVars = group.unwrap().keys().toArray();
    var externalVars = result.allExternalVars.distinct();
    var allVars = definedVars.concat(externalVars); // these should not overlap if the expand was done correctly
    var dependencySortedVars = dependencySortVars(expandedGroup, allVars);

    return new AnalyzeResult({
      analyzedExprs: result.analyzedExprs,
      externalVars: externalVars,
      definedVars: definedVars,
      allVars: allVars,
      dependencySortedVars: dependencySortedVars,
    });
  }

  public static function dependencySortVars<V, A>(group : AnnotatedExprGroup<V, A>, vars : Array<String>) : Array<String> {
    var seen : Map<String, Bool> = new Map();
    return vars.reduce(function(graph : graphx.StringGraph, name : String) : graphx.StringGraph {
      if (seen.exists(name)) { // performance optimization to skip variables we've already seen
        return graph;
      }
      seen.set(name, true);
      graph.addNode(name);
      group.getVar(name).each(function(annotatedExpr : AnnotatedExpr<V, A>) : Void {
        var depVars = annotatedExpr.getVarsArray();
        for (depVar in depVars) {
          graph.addNode(depVar);
        }
        graph.addEdgesTo(name, NodeOrValue.mapValues(depVars));
      });
      return graph;
    }, new graphx.StringGraph())
    .topologicalSort();
  }
}

class AnalyzeResult<V, A> {
  public var analyzedExprs(default, null) : Map<String, AnalyzedExpr<V, A>>;
  public var allVars(default, null) : Array<String>;
  public var definedVars(default, null) : Array<String>;
  public var externalVars(default, null): Array<String>;
  public var dependencySortedVars(default, null): Array<String>;

  public function new(options: {
    analyzedExprs : Map<String, AnalyzedExpr<V, A>>,
    allVars : Array<String>,
    definedVars : Array<String>,
    externalVars : Array<String>,
    dependencySortedVars : Array<String>
  }) {
    this.analyzedExprs = options.analyzedExprs;
    this.allVars = options.allVars;
    this.definedVars = options.definedVars;
    this.externalVars = options.externalVars;
    this.dependencySortedVars = options.dependencySortedVars;
  }

  public static function schema<E, V, A>(analyzedExprSchema : Schema<E, AnalyzedExpr<V, A>>) : Schema<E, AnalyzeResult<V, A>> {
    return object(ap5(
      (a, all, def, ext, dep) -> new AnalyzeResult({
        analyzedExprs: a,
        allVars: all,
        definedVars: def,
        externalVars: ext,
        dependencySortedVars: dep
      }),
      required("analyzedExprs", dict(analyzedExprSchema), (obj : AnalyzeResult<V, A>) -> obj.analyzedExprs),
      required("allVars", array(string()), (obj : AnalyzeResult<V, A>) -> obj.allVars),
      required("definedVars", array(string()), (obj : AnalyzeResult<V, A>) -> obj.definedVars),
      required("externalVars", array(string()), (obj : AnalyzeResult<V, A>) -> obj.externalVars),
      required("dependencySortedVars", array(string()), (obj : AnalyzeResult<V, A>) -> obj.dependencySortedVars)
    ));
  }

#if js
  public static function logPlainString<V, A>(result : AnalyzeResult<V, A>) : Void {
    var log = js.Node.console.log;
    log('--------------');
    log('Analyze Result');
    log('--------------');

    log('All vars ${result.allVars.length}');
    for (v in result.allVars.order(thx.Strings.compare)) {
      log('  $v');
    }

    log('Defined vars ${result.definedVars.length}');
    for (v in result.definedVars.order(thx.Strings.compare)) {
      log('  $v');
    }

    log('External vars ${result.externalVars.length}');
    for (v in result.externalVars.order(thx.Strings.compare)) {
      log('  $v');
    }

    log('Sorted vars ${result.dependencySortedVars.length}');
    for (v in result.dependencySortedVars) {
      log('  $v');
    }

    log('Expressions');
    for (key in result.analyzedExprs.keys().toArray().order(thx.Strings.compare)) {
      var a = result.analyzedExprs.get(key);
      log('  ---------------------------');
      log('  $key');
      log('    original:');
      log('      ${a.originalExprString}');
      log('    expanded:');
      log('      ${a.expandedExprString}');
    }
  }
#end
}

class AnalyzedExpr<V, A> {
  public var originalExpr(default, null) : AnnotatedExpr<V, A>;
  public var originalExprString(default, null) : String;
  public var originalVars(default, null) : Array<String>;
  public var expandedExpr(default, null) : AnnotatedExpr<V, Unit>;
  public var expandedExprString(default, null) : String;
  public var expandedVars(default, null) : Array<String>;

  public function new(options: {
    originalExpr: AnnotatedExpr<V, A>,
    originalExprString: String,
    originalVars: Array<String>,
    expandedExpr: AnnotatedExpr<V, Unit>,
    expandedExprString: String,
    expandedVars: Array<String>
  }) {
    this.originalExpr = options.originalExpr;
    this.originalExprString = options.originalExprString;
    this.originalVars = options.originalVars;
    this.expandedExpr = options.expandedExpr;
    this.expandedExprString = options.expandedExprString;
    this.expandedVars = options.expandedVars;
  }

  public static function schema<E, V, A>(annotatedExprASchema : Schema<E, AnnotatedExpr<V, A>>, annotatedExprUnitSchema : Schema<E, AnnotatedExpr<V, Unit>>) : Schema<E, AnalyzedExpr<V, A>> {
    return object(ap6(
      (oe, os, ov, ee, es, ev) -> new AnalyzedExpr({
        originalExpr: oe,
        originalExprString: os,
        originalVars: ov,
        expandedExpr: ee,
        expandedExprString: es,
        expandedVars: ev,
      }),
      required("originalExpr", annotatedExprASchema, (a : AnalyzedExpr<V, A>) -> a.originalExpr),
      required("originalExprString", string(), (a : AnalyzedExpr<V, A>) -> a.originalExprString),
      required("originalVars", array(string()), (a : AnalyzedExpr<V, A>) -> a.originalVars),
      required("expandedExpr", annotatedExprUnitSchema, (a : AnalyzedExpr<V, A>) -> a.expandedExpr),
      required("expandedExprString", string(), (a : AnalyzedExpr<V, A>) -> a.expandedExprString),
      required("expandedVars", array(string()), (a : AnalyzedExpr<V, A>) -> a.expandedVars)
    ));
  }
}
