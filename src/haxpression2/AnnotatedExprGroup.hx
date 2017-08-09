package haxpression2;

import haxe.ds.Option;

using thx.Arrays;
using thx.Eithers;
using thx.Maps;
import thx.Nel;
using thx.Options;
import thx.Tuple;
import thx.Validation;
import thx.Validation.*;

using haxpression2.AnnotatedExpr;
using haxpression2.AnnotatedExprGroup;
using haxpression2.Expr;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
import haxpression2.render.ExprRenderer;

typedef AnnotatedExprGroupImpl<V, A> = Map<String, AnnotatedExpr<V, A>>;

abstract AnnotatedExprGroup<V, A>(AnnotatedExprGroupImpl<V, A>) from AnnotatedExprGroupImpl<V, A> to AnnotatedExprGroupImpl<V, A> {
  public function new(value : AnnotatedExprGroupImpl<V, A>) {
    this = value;
  }

  public static function unwrap<V, A>(group : AnnotatedExprGroup<V, A>) : AnnotatedExprGroupImpl<V, A> {
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
    parserOptions: ExprParserOptions<V, N, A>
  ) : VNel<ParseError<AnnotatedExpr<V, A>>, AnnotatedExprGroup<V, A>> {
    var coalesceMap : Map<String, String> = fallbackMap.mapValues(function(exprStrings : Array<String>) : String {
      return '${coalesceFunctionName}(${exprStrings.join(", ")})';
    }, new Map());
    return parseStringMap(coalesceMap, parserOptions);
  }

  public static function mapAnnotation<V, A, B>(group : AnnotatedExprGroup<V, A>, f: String -> AnnotatedExpr<V, A> -> B) : AnnotatedExprGroup<V, B> {
    return group.foldLeftWithKeys(function(acc : AnnotatedExprGroup<V, B>, name : String, ae : AnnotatedExpr<V, A>) : AnnotatedExprGroup<V, B> {
      acc.setVar(name, ae.mapAnnotation(ae -> f(name, ae)));
      return acc;
    }, new Map());
  }

  public static function renderString<V, A>(group : AnnotatedExprGroup<V, A>, valueToString: V -> String) : String {
    return group.foldLeftWithKeys(function(acc : Array<String>, key : String, value: AnnotatedExpr<V, A>) : Array<String> {
      return acc.append('$key: ${ExprRenderer.renderString(value.expr, valueToString)}');
    }, [])
    .join("\n");
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

  public static function expand<V, A>(group : AnnotatedExprGroup<V, A>) : AnnotatedExprGroup<V, ExpandMeta<V, A>> {
    var expandedGroup = group.mapAnnotation(function(name : String, ae : AnnotatedExpr<V, A>) : ExpandMeta<V, A> {
      return new ExpandMeta({
        original: { ae: ae, vars: ae.getVarsArray() },
        expanded: None
      });
    });
    while (canExpand(expandedGroup)) {
      expandedGroup = expandOnce(expandedGroup);
    }
    return expandedGroup;
  }

  public static function expandOnce<V, A>(group : AnnotatedExprGroup<V, ExpandMeta<V, A>>) : AnnotatedExprGroup<V, ExpandMeta<V, A>> {
    return group.foldLeftWithKeys(function(group : AnnotatedExprGroup<V, ExpandMeta<V, A>>, name : String, ae : AnnotatedExpr<V, ExpandMeta<V, A>>) {
      return group.setVar(name, expandAnnotatedExpr(group, ae));
    }, group);
  }

  public static function expandAnnotatedExpr<V, A>(
    group : AnnotatedExprGroup<V, ExpandMeta<V, A>>,
    ae : AnnotatedExpr<V, ExpandMeta<V, A>>
  ) : AnnotatedExpr<V, ExpandMeta<V, A>> {
    return switch ae.expr {
      case ELit(_) : ae;
      case EVar(name) :
        group.getVar(name).cataf(
          () -> ae,
          exprForName -> ae.substitute(name, exprForName)
        );
      case EFunc(name, args) :
        var expanded : Expr<V, ExpandMeta<V, A>> = EFunc(name, args.map(arg -> expandAnnotatedExpr(group, arg)));
        new AnnotatedExpr(expanded, ae.annotation.withExpanded(expanded));
      case EBinOp(op, prec, left, right) :
        var expanded = EBinOp(op, prec, expandAnnotatedExpr(group, left), expandAnnotatedExpr(group, right));
        new AnnotatedExpr(expanded, ae.annotation.withExpanded(expanded));
      case EUnOpPre(op, prec, operand) :
        var expanded = EUnOpPre(op, prec, expandAnnotatedExpr(group, operand));
        new AnnotatedExpr(expanded, ae.annotation.withExpanded(expanded));
    };
  }

  // public function analyze() : AnalyzeResult<V, A> {
  // }

  // public function expandExpressionForVariable(name : String) : VNel<String, Expr<V, A>> {
  //   return this.getOption(name).cataf(
  //     () -> failureNel('no variable found in group for $name'),
  //     ae -> successNel(expandExpr(ae.expr))
  //   );
  // }

  // public function expandExpr(expr : Expr<V, A>) : Expr<V, A> {
  //   return switch expr {
  //     case e = ELit(_) : e;
  //     case e = EVar(name) : e;
  //     case EFunc(name, argExprs) :
  //   };
  // }
}

class AnalyzeResult<V, A> {
  public var annotatedExprGroup(default, null) : AnnotatedExprGroup<V, ExpandMeta<V, A>>;
  public var externalVars(default, null): Array<String>;
  public var orderedVars(default, null): Array<String>;
}

typedef OriginalMeta<V, A> = {
  ae: AnnotatedExpr<V, A>,
  vars: Array<String>
};

typedef ExpandedMeta<V, A> = {
  ae: Expr<V, ExpandMeta<V, A>>,
  vars: Array<String>
};

class ExpandMeta<V, A> {
  public var original(default, null) : OriginalMeta<V, A>;
  public var expanded(default, null) : Option<ExpandedMeta<V, A>>;

  public function new(options: { original : OriginalMeta<V, A>, expanded: Option<ExpandedMeta<V, A>> }) {
    this.original = options.original;
    this.expanded = options.expanded;
  }

  public function withExpanded(expanded : Expr<V, ExpandMeta<V, A>>) : ExpandMeta<V, A> {
    return new ExpandMeta({
      original: this.original,
      expanded: Some({
        ae: expanded,
        vars: expanded.getVars()
      })
    });
  }
}
