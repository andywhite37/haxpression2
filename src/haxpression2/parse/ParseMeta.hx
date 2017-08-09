package haxpression2.parse;

import Parsihax;

class ParseMeta {
  public var index(default, null) : Index;

  public function new(index : Index) {
    this.index = index;
  }

  public static function create(offset: Int, line: Int, column: Int) : ParseMeta {
    return new ParseMeta({ offset: offset, line: line, column: column });
  }

  public function toString() {
    return 'ParseMeta(${index.offset}, ${index.line}, ${index.column})';
  }

  public static function renderString(p : ParseMeta) : String {
    return p.toString();
  }
}
