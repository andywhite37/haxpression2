package haxpression2.compile;

import haxe.ds.Option;

using thx.Arrays;
using thx.Functions;
import thx.Nel;
import thx.Validation;
import thx.Validation.*;

import haxpression2.Value;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
import haxpression2.parse.ParseMeta;

enum DataType<V> {
  DTNum<N : Float> : DataType<Uncertain<N>>;
  DTBool : DataType<Bool>;
  DTStr : DataType<String>;
  DTSpan : DataType<Span>;
}

enum TimeUnit {
  Year;
  Month;
  Day;
}

enum Span {
  Span(v : Float, unit : TimeUnit);
}

enum Uncertain<V> {
  NA : Uncertain<V>;
  NM : Uncertain<V>;
  Val(v : V) : Uncertain<V>;
}

enum FuncType<V> {
  ToFloat(operand : AnnotatedCompiledExpr<Uncertain<Int>, ParseMeta>) : FuncType<Uncertain<Float>>;
  Round(operand : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>) : FuncType<Uncertain<Int>>;
  Floor(operand : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>) : FuncType<Uncertain<Int>>;
  Ceil(operand : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>) : FuncType<Uncertain<Int>>;
  Coalesce<U>(args : Array<AnnotatedCompiledExpr<U, ParseMeta>>) : FuncType<U>;
  CAGR(operand : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>, span : AnnotatedCompiledExpr<Span, ParseMeta>) : FuncType<Uncertain<Float>>;
}

enum NumBinOpType<N : Float> {
  Add(left : AnnotatedCompiledExpr<Uncertain<N>, ParseMeta>, right : AnnotatedCompiledExpr<Uncertain<N>, ParseMeta>) : NumBinOpType<N>;
}

enum BoolBinOpType {
  And(left : AnnotatedCompiledExpr<Bool, ParseMeta>, right : AnnotatedCompiledExpr<Bool, ParseMeta>);
}

enum CompiledExpr<T> {
  CELit(dataType : DataType<T>, value : T) : CompiledExpr<T>;
  CEVar(dataType : DataType<T>, name : String) : CompiledExpr<T>;
  CEFunc(funcType : FuncType<T>) : CompiledExpr<T>;
  CENumBinOp<N : Float>(binOpType : NumBinOpType<N>) : CompiledExpr<Uncertain<N>>;
  CEBoolBinOp(binOpType : BoolBinOpType) : CompiledExpr<Bool>;
}

class AnnotatedCompiledExpr<V, A> {
  public var compiledExpr(default, null) : CompiledExpr<V>;
  public var annotation(default, null) : A;

  public function new(compiledExpr, annotation) {
    this.compiledExpr = compiledExpr;
    this.annotation = annotation;
  }
}

enum AnnotatedCompiledExprCapture<A> {
  CE<V>(dataType : DataType<V>, compiledExpr : AnnotatedCompiledExpr<V, A>);
}

class CompileError extends thx.Error {
  public var parseMeta(default, null) : ParseMeta;
  public function new(message : String, parseMeta: ParseMeta, ?stack : Array<haxe.CallStack.StackItem>, ?pos : haxe.PosInfos) {
    super(message, stack, pos);
    this.parseMeta = parseMeta;
  }
  public override function toString() : String {
    return '$message (position: ${parseMeta.index.offset})';
  }
}

class CompileMeta {
  public var parseMeta(default, null) : ParseMeta;
  public function new(parseMeta) {
    this.parseMeta = parseMeta;
  }
}

typedef ExprCompilerOptions<V> = {
  compileLit :
    V ->
    ParseMeta ->
    VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>>,

  compileVar :
    String ->
    ParseMeta ->
    VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>>,

  compileFunc :
    String ->
    Array<AnnotatedExpr<V, ParseMeta>> ->
    ParseMeta ->
    ExprCompilerOptions<V> ->
    VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>>,

  compileBinOp :
    String ->
    Int ->
    AnnotatedExpr<V, ParseMeta> ->
    AnnotatedExpr<V, ParseMeta> ->
    ParseMeta ->
    ExprCompilerOptions<V> ->
    VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>>,

  compileUnOpPre :
    String ->
    Int ->
    AnnotatedExpr<V, ParseMeta> ->
    ParseMeta ->
    ExprCompilerOptions<V> ->
    VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>>
};

enum ExprStringCompilerResult<V> {
  ParseError(error : ParseError<AnnotatedExpr<V, ParseMeta>>);
  CompileErrors(errors : Nel<CompileError>);
  Compiled(compiledExpr : AnnotatedCompiledExprCapture<ParseMeta>);
}

class ExprCompiler {
  public static function compile<V>(ae : AnnotatedExpr<V, ParseMeta>, options : ExprCompilerOptions<V>) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return switch ae.expr {
      case ELit(value) : options.compileLit(value, ae.annotation);
      case EVar(name) : options.compileVar(name, ae.annotation);
      case EBinOp(op, prec, left, right) : options.compileBinOp(op, prec, left, right, ae.annotation, options);
      case EFunc(name, args) : options.compileFunc(name, args, ae.annotation, options);
      case EUnOpPre(op, prec, operand) : options.compileUnOpPre(op, prec, operand, ae.annotation, options);
    }
  }

  public static function parseAndCompile<N>(
    input : String,
    parserOptions: ExprParserOptions<Value<N>, N, ParseMeta>,
    compilerOptions: ExprCompilerOptions<Value<N>>
  ) : ExprStringCompilerResult<Value<N>> {
    return switch ExprParser.parseString(input, parserOptions) {
      case Left(parseError) : ParseError(parseError);
      case Right(ae) : switch compile(ae, compilerOptions) {
        case Left(compileError) : CompileErrors(compileError);
        case Right(compiledExpr) : Compiled(compiledExpr);
      }
    };
  }

  public static function getSimpleExprCompilerOptions() : ExprCompilerOptions<Value<Float>> {
    return {
      compileLit: compileLit,
      compileVar: compileVar,
      compileFunc: compileFunc,
      compileBinOp: compileBinOp,
      compileUnOpPre: compileUnOpPre
    };
  }

  public static function compileLit<V, N>(value : Value<Float>, meta : ParseMeta) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return switch value {
      case VNA : successNel(CE(DTNum, new AnnotatedCompiledExpr(CELit(DTNum, NA), meta)));
      case VNM : successNel(CE(DTNum, new AnnotatedCompiledExpr(CELit(DTNum, NM), meta)));
      case VInt(v) : successNel(CE(DTNum, new AnnotatedCompiledExpr(CELit(DTNum, Val(v)), meta)));
      case VNum(v) : successNel(CE(DTNum, new AnnotatedCompiledExpr(CELit(DTNum, Val(v)), meta)));
      case VBool(v) : successNel(CE(DTBool, new AnnotatedCompiledExpr(CELit(DTBool, v), meta)));
      case VStr(v) : successNel(CE(DTStr, new AnnotatedCompiledExpr(CELit(DTStr, v), meta)));
    };
  }

  public static function compileVar(name : String, meta : ParseMeta) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    // Assume all variables are of type Number, otherwise we need a lookup map from variable to type, or some other naming convention
    return successNel(CE(DTNum, new AnnotatedCompiledExpr(CEVar(DTNum, name), meta)));
  }

  public static function compileFunc(
    name : String,
    args : Array<AnnotatedExpr<Value<Float>, ParseMeta>>,
    meta : ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return switch name {
      case "COALESCE": compileFuncCoalesce(name, args, meta, options);
      case "CAGR": compileFuncCAGR(name, args, meta, options).map(ace -> CE(DTNum, ace));
      case unk : failureNel(new CompileError('Unknown function: "${name}"', meta));
    };
  }

  public static function compileFuncCoalesce<V>(
    name : String,
    args : Array<AnnotatedExpr<Value<Float>, ParseMeta>>,
    meta : ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return args.traverseValidation(arg -> ExprCompiler.compile(arg, options), Nel.semigroup())
      .flatMapV(function(compiledArgs : Array<AnnotatedCompiledExprCapture<ParseMeta>>) {
        return if (compiledArgs.length == 0) {
          failureNel(new CompileError('Function "$name" must have at least one argument', meta));
        } else {
          switch compiledArgs[0] {
            case CE(DTNum, _) : compiledArgs.traverseValidation(ensureNumberExpr, Nel.semigroup()).map(args -> CE(DTNum, new AnnotatedCompiledExpr(CEFunc(Coalesce(args)), meta)));
            case CE(DTStr, _) : compiledArgs.traverseValidation(ensureStringExpr, Nel.semigroup()).map(args -> CE(DTStr, new AnnotatedCompiledExpr(CEFunc(Coalesce(args)), meta)));
            case CE(DTBool, _) : compiledArgs.traverseValidation(ensureBoolExpr, Nel.semigroup()).map(args -> CE(DTBool, new AnnotatedCompiledExpr(CEFunc(Coalesce(args)), meta)));
            case CE(DTSpan, _) : compiledArgs.traverseValidation(ensureSpanExpr, Nel.semigroup()).map(args -> CE(DTSpan, new AnnotatedCompiledExpr(CEFunc(Coalesce(args)), meta)));
          }
        }
      });
  }

  public static function compileFuncCAGR(name : String, args : Array<AnnotatedExpr<Value<Float>, ParseMeta>>, meta : ParseMeta, options: ExprCompilerOptions<Value<Float>>) : VNel<CompileError, AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>> {
    return if (args.length != 2) {
      failureNel(new CompileError('"CAGR" function requires exactly two arguments', meta));
    } else {
      return val2(
        function(number, span) {
          return new AnnotatedCompiledExpr(CEFunc(CAGR(number, span)), meta);
        },
        ExprCompiler.compile(args[0], options).flatMapV(ensureNumberExpr),
        ExprCompiler.compile(args[1], options).flatMapV(ensureSpanExpr),
        Nel.semigroup()
      );
    }
  }

  public static function compileBinOp(
    operator : String,
    precedence : Int,
    left : AnnotatedExpr<Value<Float>, ParseMeta>,
    right : AnnotatedExpr<Value<Float>, ParseMeta>,
    meta: ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return switch operator {
      case "+" : compileBinOpNumberAdd(operator, precedence, left, right, meta, options).map(ace -> CE(DTNum, ace));
      case unk : failureNel(new CompileError('Unknown binary operator: \"$operator\"', meta));
    }
  }

  public static function compileBinOpNumberAdd<V : Float>(
    operator : String,
    precedence : Int,
    left : AnnotatedExpr<Value<Float>, ParseMeta>,
    right : AnnotatedExpr<Value<Float>, ParseMeta>,
    meta: ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExpr<Uncertain<V>, ParseMeta>> {
    return val2(
      function(left : AnnotatedCompiledExpr<Uncertain<V>, ParseMeta>, right : AnnotatedCompiledExpr<Uncertain<V>, ParseMeta>) : AnnotatedCompiledExpr<Uncertain<V>, ParseMeta> {
        return new AnnotatedCompiledExpr(CENumBinOp(Add(left, right)), meta);
      },
      ExprCompiler.compile(left, options).flatMapV(ensureNumberExpr),
      ExprCompiler.compile(right, options).flatMapV(ensureNumberExpr),
      Nel.semigroup()
    );
  }

  public static function compileUnOpPre<V>(
    operator : String,
    precedence : Int,
    operand : AnnotatedExpr<Value<Float>, ParseMeta>,
    meta: ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return switch operator {
      case unk : failureNel(new CompileError('Unknown prefix unary operator: \"$operator\"', meta));
    }
  }

  public static function ensureNumberExpr<U, V : Float>(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<Uncertain<V>, ParseMeta>> {
    return switch acec {
      case CE(DTNum, ace) : successNel(ace);
      case CE(DTStr, ace) : failureNel(new CompileError('Expected a number expression, but found a string expression', ace.annotation));
      case CE(DTBool, ace) : failureNel(new CompileError('Expected a number expression, but found a boolean expression', ace.annotation));
      case CE(DTSpan, ace) : failureNel(new CompileError('Expected a number expression, but found a span expression', ace.annotation));
    }
  }

  public static function ensureStringExpr<U, V : Float>(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<String, ParseMeta>> {
    return switch acec {
      case CE(DTNum, ace) : failureNel(new CompileError('Expected a string expression, but found a number expression', ace.annotation));
      case CE(DTStr, ace) : successNel(ace);
      case CE(DTBool, ace) : failureNel(new CompileError('Expected a string expression, but found a boolean expression', ace.annotation));
      case CE(DTSpan, ace) : failureNel(new CompileError('Expected a string expression, but found a span expression', ace.annotation));
    }
  }

  public static function ensureBoolExpr<U, V : Float>(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<Bool, ParseMeta>> {
    return switch acec {
      case CE(DTNum, ace) : failureNel(new CompileError('Expected a bool expression, but found a number expression', ace.annotation));
      case CE(DTStr, ace) : failureNel(new CompileError('Expected a bool expression, but found a string expression', ace.annotation));
      case CE(DTBool, ace) : successNel(ace);
      case CE(DTSpan, ace) : failureNel(new CompileError('Expected a bool expression, but found a span expression', ace.annotation));
    }
  }

  public static function ensureSpanExpr<U, V : Float>(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<Span, ParseMeta>> {
    return switch acec {
      case CE(DTNum, ace) : failureNel(new CompileError('Expected a span expression, but found a number expression', ace.annotation));
      case CE(DTStr, ace) : switch ace.compiledExpr {
        case CELit(DTStr, str) : parseSpan(str, ace.annotation).map(span -> new AnnotatedCompiledExpr(CELit(DTSpan, span), ace.annotation));
        case CEVar(_) : failureNel(new CompileError('span argument must be a string literal', ace.annotation));
        case CEFunc(_) : failureNel(new CompileError('span argument must be a string literal', ace.annotation));
      };
      case CE(DTBool, ace) : failureNel(new CompileError('Expected a span expression, but found a boolean expression', ace.annotation));
      case CE(DTSpan, ace) : successNel(ace);
    }
  }

  public static function parseSpan(str : String, meta : ParseMeta) : VNel<CompileError, Span> {
    var regex = ~/(\d+)([ymd])/i;
    return if (regex.match(str)) {
      var intPart : Int = Std.parseInt(regex.matched(1));
      var unitPart = regex.matched(2);
      switch unitPart.toLowerCase() {
        case "y" : successNel(Span(intPart, Year));
        case "m" : successNel(Span(intPart, Month));
        case "d" : successNel(Span(intPart, Day));
        case _ : failureNel(new CompileError('invalid unit in span string literal: $str', meta)); // this should not happen
      }
    } else {
      failureNel(new CompileError('string "$str" is not a valid span string', meta));
    }
  }
}
