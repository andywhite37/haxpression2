package haxpression2;

class ParseMeta {
  public var index(default, null) : Int;

  public function new(index : Int) {
    this.index = index;
  }

  public static function meta(index : Int) : ParseMeta {
    return new ParseMeta(index);
  }
}
