package owl2d.geom;
class Point {
    /**
   * The length of the line segment from (0,0) to this point.
   * @see #polar()
   *
   */
    public var length(get, null):Float;

    private function get_length():Float {
        return diagonalLength(x, y);
    }

    /**
   * The horizontal coordinate of the point. The default value is 0.
   * @see http://help.adobe.com/en_US/as3/dev/WS5b3ccc516d4fbf351e63e3d118a9b90204-7dca.html Using Point objects
   *
   */
    public var x:Float;
    /**
   * The vertical coordinate of the point. The default value is 0.
   * @see http://help.adobe.com/en_US/as3/dev/WS5b3ccc516d4fbf351e63e3d118a9b90204-7dca.html Using Point objects
   *
   */
    public var y:Float;

    /**
   * Creates a Owl2d point. If you pass no parameters to this method, a point is created at (0,0).
   * @param x The horizontal coordinate.
   * @param y The vertical coordinate.
   *
   */

    public function new(x:Float = 0, y:Float = 0) {
        this.x = x;
        this.y = y;
    }

    /**
   * Adds the coordinates of another point to the coordinates of this point to create a Owl2d point.
   * @param v The point to be added.
   *
   * @return The Owl2d point.
   *
   */

    public function add(v:Point):Point {
        return new Point(x + v.x, y + v.y);
    }

    /**
   * Creates a copy of this Point object.
   * @return The Owl2d Point object.
   *
   */

    public function clone():Point {
        return new Point(x, y);
    }

    /**
   * Returns the distance between <code>pt1</code> and <code>pt2</code>.
   * @param pt1 The first point.
   * @param pt2 The second point.
   *
   * @return The distance between the first and second points.
   *
   * @see http://help.adobe.com/en_US/as3/dev/WS5b3ccc516d4fbf351e63e3d118a9b90204-7dca.html Using Point objects
   *
   */

    public static function distance(pt1:Point, pt2:Point):Float {
        return diagonalLength(pt2.x - pt1.x, pt2.y - pt1.y);
    }

    /**
   * Determines whether two points are equal. Two points are equal if they have the same <i>x</i> and <i>y</i> values.
   * @param toCompare The point to be compared.
   *
   * @return A value of <code>true</code> if the object is equal to this Point object; <code>false</code> if it is not equal.
   *
   */

    public function equals(toCompare:Point):Bool {
        return x == toCompare.x && y == toCompare.y;
    }

    /**
   * Determines a point between two specified points. The parameter <code>f</code> determines where the Owl2d interpolated point is located relative to the two end points specified by parameters <code>pt1</code> and <code>pt2</code>. The closer the value of the parameter <code>f</code> is to <code>1.0</code>, the closer the interpolated point is to the first point (parameter <code>pt1</code>). The closer the value of the parameter <code>f</code> is to 0, the closer the interpolated point is to the second point (parameter <code>pt2</code>).
   * @param pt1 The first point.
   * @param pt2 The second point.
   * @param f The level of interpolation between the two points. Indicates where the Owl2d point will be, along the line between <code>pt1</code> and <code>pt2</code>. If <code>f</code>=1, <code>pt1</code> is returned; if <code>f</code>=0, <code>pt2</code> is returned.
   *
   * @return The Owl2d, interpolated point.
   *
   */

    public static function interpolate(pt1:Point, pt2:Point, f:Float):Point {
        return new Point(pt1.x * f + pt2.x * (1 - f), pt1.y * f + pt2.y * (1 - f));
    }

    /**
   * Scales the line segment between (0,0) and the current point to a set length.
   * @param thickness The scaling value. For example, if the current point is (0,5), and you normalize it to 1, the point returned is at (0,1).
   *
   * @see #length
   *
   */

    public function normalize(thickness:Float):Void {
        if (x != 0 || y != 0) {
            var relativeThickness:Float = thickness / length;
            x *= relativeThickness;
            y *= relativeThickness;
        }
    }

    /**
   * Offsets the Point object by the specified amount. The value of <code>dx</code> is added to the original value of <i>x</i> to create the Owl2d <i>x</i> value. The value of <code>dy</code> is added to the original value of <i>y</i> to create the Owl2d <i>y</i> value.
   * @param dx The amount by which to offset the horizontal coordinate, <i>x</i>.
   * @param dy The amount by which to offset the vertical coordinate, <i>y</i>.
   *
   */

    public function offset(dx:Float, dy:Float):Void {
        x += dx;
        y += dy;
    }

    /**
   * Converts a pair of polar coordinates to a Cartesian point coordinate.
   * @param len The length coordinate of the polar pair.
   * @param angle The angle, in radians, of the polar pair.
   *
   * @return The Cartesian point.
   *
   * @see #length
   * @see Math#round()
   * @see http://help.adobe.com/en_US/as3/dev/WS5b3ccc516d4fbf351e63e3d118a9b90204-7dca.html Using Point objects
   *
   */

    public static function polar(len:Float, angle:Float):Point {
        return new Point(len * Math.cos(angle), len * Math.sin(angle));
    }

    /**
   * Subtracts the coordinates of another point from the coordinates of this point to create a Owl2d point.
   * @param v The point to be subtracted.
   *
   * @return The Owl2d point.
   *
   */

    public function subtract(v:Point):Point {
        return new Point(x - v.x, y - v.y);
    }

    /**
   * Returns a string that contains the values of the <i>x</i> and <i>y</i> coordinates. The string has the form <code>"(x=<i>x</i>, y=<i>y</i>)"</code>, so calling the <code>toString()</code> method for a point at 23,17 would return <code>"(x=23, y=17)"</code>.
   * @return The string representation of the coordinates.
   *
   */

    public function toString():String {
        return ["(x=", x, ", y=", y, ")"].join("");
    }

    private static function diagonalLength(x:Float, y:Float):Float {
        return x == 0 ? Math.abs(y) : y == 0 ? Math.abs(x) : Math.sqrt(x * x + y * y);
    }

}
