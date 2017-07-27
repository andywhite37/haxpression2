package haxpression2;

import Parsihax;

class ParseMeta {
  public var index(default, null) : Index;

  public function new(index : Index) {
    this.index = index;
  }

  public static function meta(offset: Int, line: Int, column: Int) : ParseMeta {
    return new ParseMeta({ offset: offset, line: line, column: column });
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
