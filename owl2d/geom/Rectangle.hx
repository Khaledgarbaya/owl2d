package owl2d.geom;
class Rectangle {

    public var bottom(get, set):Float;

    private function get_bottom():Float {
        return y + height;
    }

    private function set_bottom(value:Float):Float {
        height = Math.max(value - y, 0);
        return value;
    }
    public var bottomRight(get, set):Type;

    public function get_bottomRight():Point {
        return new Point(right, bottom);
    }

    public function set_bottomRight(value:Point):Point {
        right = value.x;
        bottom = value.y;
        return value;
    }
    public var height:Float;

    public var left(get, set):Float;

    private function get_left():Float {
        return x;
    }

    private function set_left(value:Float):Float {
        width += x - value; // TODO: really change width?
        x = value;
        return value;
    }
    public var right(get, set):Float;

    private function get_right():Float {
        return x + width;
    }

    private function set_right(value:Float):Float {
        width = value - x;
        return value;
    }
    public var size(get, set):Point;

    private function get_size():Point {
        return new Point(width, height);
    }

    private function set_size(value:Point):Point {
        this.width = value.x;
        this.height = value.y;
        return value;
    }

    public var top(get, set):Float;

    private function get_top():Float {
        return y;
    }

    private function set_top(value:Float):Void {
        height += y - value;
        y = value;
    }
    public var topLeft(get, set):Point;

    private function get_topLeft():Point {
        return new Point(x, y);
    }

    private function set_topLeft(value:Point):Pont {
        left = value.x;
        top = value.y;
        return value;
    }
    public var width:Float;
    public var x:Float;
    public var y:Float;

    public function new(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }

    public function clone():Rectangle {
        return new Rectangle(x, y, width, height);
    }

    public function contains(x:Float, y:Float):Bool {
        return this.x <= x && x <= this.right && this.y <= y && y <= this.bottom;
    }

    public function containsPoint(Point:Point):Bool {
        return contains(Point.x, Point.y);
    }

    public function containsRect(rect:Rectangle):Bool {
        return containsPoint(rect.topLeft) && containsPoint(rect.bottomRight);
    }

    public function equals(toCompare:Rectangle):Bool {
        return x == toCompare.x && y == toCompare.y && width == toCompare.width && height == toCompare.height;
    }

    public function inflate(dx:Float, dy:Float):Void {
        this.x -= dx;
        this.y -= dy;
        this.width += (dx * 2);
        this.height += (dy * 2);
    }

    public function inflatePoint(Point:Point):Void {
        inflate(Point.x, Point.y);
    }

    public function intersection(toIntersect:Rectangle):Rectangle {
        var x:Float = Math.max(this.x, toIntersect.x);
        var right:Float = Math.min(this.right, toIntersect.right);
        if (x <= right) {
            var y:Float = Math.max(this.y, toIntersect.y);
            var bottom:Float = Math.min(this.bottom, toIntersect.bottom);
            if (y <= bottom) {
                return new Rectangle(x, y, right - x, bottom - y);
            }
        }
        return new Rectangle();
    }

    public function intersects(toIntersect:Rectangle):Bool {
        return Math.max(this.x, toIntersect.x) <= Math.min(this.right, toIntersect.right)
        && Math.max(this.y, toIntersect.y) <= Math.min(this.bottom, toIntersect.bottom);
    }

    public function isEmpty():Bool {
        return x == 0 && y == 0 && width == 0 && height == 0;
    }

    public function offset(dx:Float, dy:Float):Void {
        x += dx;
        y += dy;
    }

    public function offsetPoint(Point:Point):Void {
        offset(Point.x, Point.y);
    }

    public function setEmpty():Void {
        this.x = this.y = this.width = this.height = 0;
    }

    public function toString():String {
        return "[Rectangle(" + [x, y, width, height].join(", ") + ")]";
    }

    public function union(toUnion:Rectangle):Rectangle {
        if (toUnion.width == 0 || toUnion.height == 0) {
            return clone();
        }
        if (width == 0 || height == 0) {
            return toUnion.clone();
        }
        var x:Float = Math.min(this.x, toUnion.x);
        var y:Float = Math.min(this.y, toUnion.y);
        return new Rectangle(x, y, Math.max(this.right, toUnion.right) - x, Math.max(this.bottom, toUnion.bottom) - y);
    }

    public function setTo(x: Float, y:Float, width:Float, height:Float):Void {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height
    }
}
