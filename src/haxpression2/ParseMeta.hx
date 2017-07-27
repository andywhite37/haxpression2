package haxpression2;

import Parsihax;

class ParseMeta {
  //public var input(default, null) : String;
  public var index(default, null) : Index;

  public function new(/*input : String,*/ index : Index) {
    //this.input = input;
    this.index = index;
  }

  public static function meta(/*input : String,*/ offset: Int, line: Int, column: Int) : ParseMeta {
    return new ParseMeta(/*input,*/ { offset: offset, line: line, column: column });
  }

  public function toString() {
    return '[o:${index.offset}, l:${index.line}, c:${index.column}]';
  }

/*
  public static function fromIndex(index : Index) : ParseMeta {
    return new ParseMeta(index);
  }

  public static function fromOffset(offset : Int) : ParseMeta {
    var index : Index = { offset: offset, line: 0, column: 0 };
    return new ParseMeta(index);
  }
  */
}
