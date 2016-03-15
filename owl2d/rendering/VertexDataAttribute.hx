package owl2d.rendering;
class VertexDataAttribute {

    public var name:String;
    public var format:Int;
    public var isColor:Bool;
    public var offset:Int; // in bytes
    public var size:Int;   // in bytes

    public function new(name:String, format:Int, offset:Int) {
        this.name = name;
        this.format = format;
        this.offset = offset;
        //this.size = size ? ; //TODO do we needs this in opengl ?
        this.isColor = name.indexOf("color") != -1 || name.indexOf("Color") != -1
    }
}
