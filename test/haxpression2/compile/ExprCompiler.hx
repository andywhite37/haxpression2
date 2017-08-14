package haxpression2.compile;

using thx.Arrays;
import thx.Nel;
import thx.Validation;
import thx.Validation.*;

import haxpression2.Value;
import haxpression2.parse.ExprParser;
import haxpression2.parse.ParseError;
import haxpression2.parse.ParseMeta;

enum DataType<V> {
  DTUInt : DataType<Uncertain<Int>>;
  DTUReal : DataType<Uncertain<Float>>;
  DTBool : DataType<Bool>;
  DTStr : DataType<String>;
  DTSpan : DataType<Span>;
}

enum Uncertain<V> {
  NA : Uncertain<V>;
  NM : Uncertain<V>;
  Val(v : V) : Uncertain<V>;
}

enum Span {
  Span(v : Float, unit : TimeUnit);
}

enum TimeUnit {
  Year;
  Month;
  Day;
}

enum CompiledFunc<V> {
  ToFloat(operand : AnnotatedCompiledExpr<Uncertain<Int>, ParseMeta>) : CompiledFunc<Uncertain<Float>>;
  Round(operand : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>) : CompiledFunc<Uncertain<Int>>;
  Floor(operand : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>) : CompiledFunc<Uncertain<Int>>;
  Ceil(operand : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>) : CompiledFunc<Uncertain<Int>>;
  Coalesce<U>(args : Array<AnnotatedCompiledExpr<U, ParseMeta>>) : CompiledFunc<U>;
  CAGR(operand : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>, span : AnnotatedCompiledExpr<Span, ParseMeta>) : CompiledFunc<Uncertain<Float>>;
}

enum CompiledIntBinOp {
}

enum CompiledRealBinOp {
  Add(left : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>, right : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>);
  Sub(left : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>, right : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>);
  Mul(left : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>, right : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>);
  Div(left : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>, right : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>);
  Mod(left : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>, right : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>);
}

typedef CreateRealBinOp =
  AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta> ->
  AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta> ->
  CompiledRealBinOp;

enum CompiledBoolBinOp {
  And(left : AnnotatedCompiledExpr<Bool, ParseMeta>, right : AnnotatedCompiledExpr<Bool, ParseMeta>);
  Or(left : AnnotatedCompiledExpr<Bool, ParseMeta>, right : AnnotatedCompiledExpr<Bool, ParseMeta>);
  Xor(left : AnnotatedCompiledExpr<Bool, ParseMeta>, right : AnnotatedCompiledExpr<Bool, ParseMeta>);
}

enum CompiledStringBinOp {
}

enum CompiledRealUnOpPre {
  Negate(operand : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>);
}

typedef CreateRealUnOpPre = AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta> -> CompiledRealUnOpPre;

enum CompiledExpr<T> {
  CELit(dataType : DataType<T>, value : T) : CompiledExpr<T>;
  CEVar(dataType : DataType<T>, name : String) : CompiledExpr<T>;
  CEFunc(funcType : CompiledFunc<T>) : CompiledExpr<T>;
  CEIntBinOp(binOpType : CompiledIntBinOp) : CompiledExpr<Uncertain<Int>>;
  CERealBinOp(binOpType : CompiledRealBinOp) : CompiledExpr<Uncertain<Float>>;
  CEBoolBinOp(binOpType : CompiledBoolBinOp) : CompiledExpr<Bool>;
  CEStringBinOp(binOpType : CompiledStringBinOp) : CompiledExpr<String>;
  CERealUnOpPre(unOpPreType : CompiledRealUnOpPre) : CompiledExpr<Uncertain<Float>>;
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
      case VNA : successNel(CE(DTUReal, new AnnotatedCompiledExpr(CELit(DTUReal, NA), meta)));
      case VNM : successNel(CE(DTUReal, new AnnotatedCompiledExpr(CELit(DTUReal, NM), meta)));
      case VInt(v) : successNel(CE(DTUInt, new AnnotatedCompiledExpr(CELit(DTUInt, Val(v)), meta)));
      case VReal(v) : successNel(CE(DTUReal, new AnnotatedCompiledExpr(CELit(DTUReal, Val(v)), meta)));
      case VBool(v) : successNel(CE(DTBool, new AnnotatedCompiledExpr(CELit(DTBool, v), meta)));
      case VStr(v) : successNel(CE(DTStr, new AnnotatedCompiledExpr(CELit(DTStr, v), meta)));
    };
  }

  public static function compileVar(name : String, meta : ParseMeta) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    // Assume all variables are of type DTReal, otherwise we need a lookup map from variable to type, or some other naming convention
    return successNel(CE(DTUReal, new AnnotatedCompiledExpr(CEVar(DTUReal, name), meta)));
  }

  public static function compileFunc(
    name : String,
    args : Array<AnnotatedExpr<Value<Float>, ParseMeta>>,
    meta : ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExprCapture<ParseMeta>> {
    return switch name.toLowerCase() {
      case "coalesce": compileFuncCoalesce(name, args, meta, options);
      case "cagr": compileFuncCAGR(name, args, meta, options).map(ace -> CE(DTUReal, ace));
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
            case CE(DTUInt, _) : compiledArgs.traverseValidation(ensureIntExpr, Nel.semigroup()).map(args -> CE(DTUInt, new AnnotatedCompiledExpr(CEFunc(Coalesce(args)), meta)));
            case CE(DTUReal, _) : compiledArgs.traverseValidation(ensureRealExpr, Nel.semigroup()).map(args -> CE(DTUReal, new AnnotatedCompiledExpr(CEFunc(Coalesce(args)), meta)));
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
        ExprCompiler.compile(args[0], options).flatMapV(ensureRealExpr),
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
      case "+" : compileRealBinOp(operator, precedence, left, right, Add, meta, options).map(ace -> CE(DTUReal, ace));
      case "-" : compileRealBinOp(operator, precedence, left, right, Add, meta, options).map(ace -> CE(DTUReal, ace));
      case "*" : compileRealBinOp(operator, precedence, left, right, Mul, meta, options).map(ace -> CE(DTUReal, ace));
      case "/" : compileRealBinOp(operator, precedence, left, right, Div, meta, options).map(ace -> CE(DTUReal, ace));
      case "%" : compileRealBinOp(operator, precedence, left, right, Mod, meta, options).map(ace -> CE(DTUReal, ace));
      case unk : failureNel(new CompileError('Unknown binary operator: \"$operator\"', meta));
    }
  }

  public static function compileRealBinOp(
    operator : String,
    precedence : Int,
    left : AnnotatedExpr<Value<Float>, ParseMeta>,
    right : AnnotatedExpr<Value<Float>, ParseMeta>,
    createBinOp : CreateRealBinOp,
    meta: ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>> {
    return val2(
      function(left : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>, right : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>) : AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta> {
        return new AnnotatedCompiledExpr(CERealBinOp(createBinOp(left, right)), meta);
      },
      ExprCompiler.compile(left, options).flatMapV(ensureRealExpr),
      ExprCompiler.compile(right, options).flatMapV(ensureRealExpr),
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
      case "-" : compileRealUnOpPre(operator, precedence, operand, Negate, meta, options).map(ace -> CE(DTUReal, ace));
      case unk : failureNel(new CompileError('Unknown prefix unary operator: \"$operator\"', meta));
    }
  }

  public static function compileRealUnOpPre<V>(
    operator : String,
    precedence : Int,
    operand : AnnotatedExpr<Value<Float>, ParseMeta>,
    createUnOpPre : CreateRealUnOpPre,
    meta: ParseMeta,
    options: ExprCompilerOptions<Value<Float>>
  ) : VNel<CompileError, AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>> {
    return ExprCompiler.compile(operand, options)
      .flatMapV(ensureRealExpr)
      .map(compiledOperand -> new AnnotatedCompiledExpr(CERealUnOpPre(createUnOpPre(compiledOperand)), meta));
  }

  public static function ensureIntExpr(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<Uncertain<Int>, ParseMeta>> {
    return switch acec {
      case CE(DTUInt, ace) : successNel(ace);
      // Note: do not allow automatic conversion from real expression to int expression
      case CE(DTUReal, ace) : failureNel(new CompileError('Expected an integer expression, but found a real number expression', ace.annotation));
      case CE(DTStr, ace) : failureNel(new CompileError('Expected an integer expression, but found a string expression', ace.annotation));
      case CE(DTBool, ace) : failureNel(new CompileError('Expected an integer expression, but found a boolean expression', ace.annotation));
      case CE(DTSpan, ace) : failureNel(new CompileError('Expected an integer expression, but found a span expression', ace.annotation));
    }
  }

  public static function ensureRealExpr(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<Uncertain<Float>, ParseMeta>> {
    return switch acec {
      // Allow automatic conversion from int expression to real expression
      case CE(DTUInt, ace) : switch ace.compiledExpr {
        case CELit(DTUInt, NA) : successNel(new AnnotatedCompiledExpr(CELit(DTUReal, NA), ace.annotation));
        case CELit(DTUInt, NM) : successNel(new AnnotatedCompiledExpr(CELit(DTUReal, NM), ace.annotation));
        case CELit(DTUInt, Val(v)) : successNel(new AnnotatedCompiledExpr(CELit(DTUReal, Val(v * 1.0)), ace.annotation));
        case CEVar(DTUInt, name) : successNel(new AnnotatedCompiledExpr(CEVar(DTUReal, name), ace.annotation));
        case CEFunc(_) : successNel(new AnnotatedCompiledExpr(CEFunc(ToFloat(ace)), ace.annotation));
        case CEIntBinOp(_) : successNel(new AnnotatedCompiledExpr(CEFunc(ToFloat(ace)), ace.annotation));
      };
      case CE(DTUReal, ace) : successNel(ace);
      case CE(DTStr, ace) : failureNel(new CompileError('Expected a real number expression, but found a string expression', ace.annotation));
      case CE(DTBool, ace) : failureNel(new CompileError('Expected a real number expression, but found a boolean expression', ace.annotation));
      case CE(DTSpan, ace) : failureNel(new CompileError('Expected a real number expression, but found a span expression', ace.annotation));
    }
  }

  public static function ensureStringExpr(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<String, ParseMeta>> {
    return switch acec {
      case CE(DTUInt, ace) : failureNel(new CompileError('Expected a string expression, but found an integer expression', ace.annotation));
      case CE(DTUReal, ace) : failureNel(new CompileError('Expected a string expression, but found a number expression', ace.annotation));
      case CE(DTStr, ace) : successNel(ace);
      case CE(DTBool, ace) : failureNel(new CompileError('Expected a string expression, but found a boolean expression', ace.annotation));
      case CE(DTSpan, ace) : failureNel(new CompileError('Expected a string expression, but found a span expression', ace.annotation));
    }
  }

  public static function ensureBoolExpr(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<Bool, ParseMeta>> {
    return switch acec {
      case CE(DTUInt, ace) : failureNel(new CompileError('Expected a bool expression, but found an integer expression', ace.annotation));
      case CE(DTUReal, ace) : failureNel(new CompileError('Expected a bool expression, but found a number expression', ace.annotation));
      case CE(DTStr, ace) : failureNel(new CompileError('Expected a bool expression, but found a string expression', ace.annotation));
      case CE(DTBool, ace) : successNel(ace);
      case CE(DTSpan, ace) : failureNel(new CompileError('Expected a bool expression, but found a span expression', ace.annotation));
    }
  }

  public static function ensureSpanExpr(acec : AnnotatedCompiledExprCapture<ParseMeta>) : VNel<CompileError, AnnotatedCompiledExpr<Span, ParseMeta>> {
    return switch acec {
      case CE(DTUInt, ace) : failureNel(new CompileError('Expected a span expression, but found an integer expression', ace.annotation));
      case CE(DTUReal, ace) : failureNel(new CompileError('Expected a span expression, but found a number expression', ace.annotation));
      case CE(DTStr, ace) : switch ace.compiledExpr {
        case CELit(DTStr, str) : parseSpan(str, ace.annotation).map(span -> new AnnotatedCompiledExpr(CELit(DTSpan, span), ace.annotation));
        case CEVar(_) : failureNel(new CompileError('span expression must be a string literal', ace.annotation));
        case CEFunc(_) : failureNel(new CompileError('span expression must be a string literal', ace.annotation));
        case CEStringBinOp(_) : failureNel(new CompileError('span expression must be a string literal', ace.annotation));
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
