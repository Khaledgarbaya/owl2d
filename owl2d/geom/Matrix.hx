package owl2d.geom;
import types.Point;
class Matrix {
    public var a:Float;
    public var b:Float;
    public var c:Float;
    public var d:Float;
    public var tx:Float;
    public var ty:Float;

    public function new(a:Float = 1, b:Float = 0, c:Float = 0, d:Float = 1, tx:Float = 0, ty:Float = 0) {
        this.a = a;
        this.b = b;
        this.c = c;
        this.d = d;
        this.tx = tx;
        this.ty = ty;
    }

    public function clone():Matrix {
        return new Matrix(a, b, c, d, tx, ty);
    }

    public function concat(m:Matrix):Void {
        var a:Float = this.a;
        var b:Float = this.b;
        var c:Float = this.c;
        var d:Float = this.d;
        var tx:Float = this.tx;
        var ty:Float = this.ty;
        this.a = m.a * a + m.c * b;
        this.b = m.b * a + m.d * b;
        this.c = m.a * c + m.c * d;
        this.d = m.b * c + m.d * d;
        this.tx = m.a * tx + m.c * ty + m.tx;
        this.ty = m.b * tx + m.d * ty + m.ty;
    }

    public function createBox(scaleX:Float, scaleY:Float, rotation:Float = 0, tx:Float = 0, ty:Float = 0):Void {
        // all inlined for higher performance:
        if (rotation == 0) {
            a = d = 1;
            b = c = 0;
        } else {
            a = Math.cos(rotation);
            b = Math.sin(rotation);
            c = -b;
            d = a;
        }
        if (scaleX != 1) {
            a *= scaleX;
            c *= scaleX;
        }
        if (scaleY != 1) {
            b *= scaleY;
            d *= scaleY;
        }
        this.tx = tx;
        this.ty = ty;
    }

    public function createGradientBox(width:Float, height:Float, rotation:Float = 0, tx:Float = 0, ty:Float = 0):Void {
        this.createBox(width / MAGIC_GRADIENT_FACTOR, height / MAGIC_GRADIENT_FACTOR, rotation, tx + width / 2, ty + height / 2);
    }

    public function deltaTransformPoint(point:Point):Point {
        return new Point(a * point.x + c * point.y, b * point.x + d * point.y);
    }

    public function identity():Void {
        a = d = 1;
        b = c = tx = ty = 0;
    }

    public function invert():Void {
        var a:Float = this.a;
        var b:Float = this.b;
        var c:Float = this.c;
        var d:Float = this.d;
        var tx:Float = this.tx;
        var ty:Float = this.ty;
        // Cremer's rule: inverse = adjugate / determinant
        // A-1 = adj(A) / det(A)
        var det:Float = a * d - c * b;
        //     [a11 a12 a13]
        // A = [a21 a22 a23]
        //     [a31 a32 a33]
        // according to http://de.wikipedia.org/wiki/Inverse_Matrix#Formel_f.C3.BCr_3x3-Matrizen (sorry, German):
        //          [a22*a33-a32*a23 a13*a32-a12*a33 a12*a23-a13*a22]
        // adj(A) = [a23*a31-a21*a33 a11*a33-a13*a31 a13*a21-a11*a23]
        //          [a21*a32-a22*a31 a12*a31-a11*a32 a11*a22-a12*a21]
        // with a11 = a, a12 = c, a13 = tx,
        //      a21 = b, a22 = d, a23 = ty,
        //      a31 = 0, a32 = 0, a33 = 1:
        //          [d *1-0*ty  tx*0-c *1  c *ty-tx*d ]
        // adj(A) = [ty*0-b* 1  a *1-tx*0  tx* b-a *ty]
        //          [b *0-d* 0  c *0-a *0  a * d-c *b ]
        //          [ d -c  c*ty-tx*d]
        //        = [-b  a  tx*b-a*ty]
        //          [ 0  0  a*d -c*b ]
        this.a = d / det;
        this.b = -b / det;
        this.c = -c / det;
        this.d = a / det;
        //this.tx = (c*ty-tx*d)/det;
        //this.ty = (tx*b-a*ty)/det;
        // Dart version:
        this.tx = -(this.a * tx + this.c * ty);
        this.ty = -(this.b * tx + this.d * ty);
    }

    /**
   * Applies a rotation transformation to the Matrix object.
   * <p>The <code>rotate()</code> method alters the <code>a</code>, <code>b</code>, <code>c</code>, and <code>d</code> properties of the Matrix object. In matrix notation, this is the same as concatenating the current matrix with the following:</p>
   * <p><img src="http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/images/matrix_rotate.jpg" /></p>
   * @param angle The rotation angle in radians.
   *
   * @see http://help.adobe.com/en_US/as3/dev/WS5b3ccc516d4fbf351e63e3d118a9b90204-7ddb.html Using Matrix objects
   *
   */

    public function rotate(angle:Float):Void {
        /*
        with sin = sin(angle) and cos = cos(angle):
                      [a            c            tx           ]
                      [b            d            ty           ]
                      [0            0            1            ]
      [cos   -sin  0] [a*cos-b*sin  c*cos-d*sin  tx*cos-ty*sin]
      [sin   cos   0] [a*sin+b*cos  c*sin+d*cos  tx*sin+ty*cos]
      [0     0     1] [0            0            1            ]
    */
        if (angle != 0) {
            var cos:Float = Math.cos(angle);
            var sin:Float = Math.sin(angle);
            var a:Float = this.a;
            var b:Float = this.b;
            var c:Float = this.c;
            var d:Float = this.d;
            var tx:Float = this.tx;
            var ty:Float = this.ty;
            this.a = a * cos - b * sin;
            this.b = a * sin + b * cos;
            this.c = c * cos - d * sin;
            this.d = c * sin + d * cos;
            this.tx = tx * cos - ty * sin;
            this.ty = tx * sin + ty * cos;
        }
    }

    /**
   * Applies a scaling transformation to the matrix. The <i>x</i> axis is multiplied by <code>sx</code>, and the <i>y</i> axis it is multiplied by <code>sy</code>.
   * <p>The <code>scale()</code> method alters the <code>a</code> and <code>d</code> properties of the Matrix object. In matrix notation, this is the same as concatenating the current matrix with the following matrix:</p>
   * <p><img src="http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/images/matrix_scale.jpg" /></p>
   * @param sx A multiplier used to scale the object along the <i>x</i> axis.
   * @param sy A multiplier used to scale the object along the <i>y</i> axis.
   *
   * @see http://help.adobe.com/en_US/as3/dev/WS5b3ccc516d4fbf351e63e3d118a9b90204-7ddb.html Using Matrix objects
   *
   */

    public function scale(sx:Float, sy:Float):Void {
        /*
                      [a     c    tx   ]
                      [b     d    ty   ]
                      [0     0    1    ]

      [sx    0     0] [a*sx  c*sx tx*sx]
      [0     sy    0] [b*sy  d*sy ty*sy]
      [0     0     1] [0     0    1    ]
    */
        if (sx != 1) {
            a *= sx;
            c *= sx;
            tx *= sx;
        }
        if (sy != 1) {
            b *= sy;
            d *= sy;
            ty *= sy;
        }
    }

    /**
   * Returns a text value listing the properties of the Matrix object.
   * @return A string containing the values of the properties of the Matrix object: <code>a</code>, <code>b</code>, <code>c</code>, <code>d</code>, <code>tx</code>, and <code>ty</code>.
   *
   */

    public function toString():String {
        return "(" + ["a=" + a, "b=" + b, "c=" + c, "d=" + d, "tx=" + tx, "ty=" + ty].join(", ") + ")";
    }

    /**
   * Returns the result of applying the geometric transformation represented by the Matrix object to the specified point.
   * @param point The point for which you want to get the result of the Matrix transformation.
   *
   * @return The point resulting from applying the Matrix transformation.
   *
   */

    public function transformPoint(point:Point):Point {
        return new Point(a * point.x + c * point.y + tx, b * point.x + d * point.y + ty);
    }

    /**
   * Translates the matrix along the <i>x</i> and <i>y</i> axes, as specified by the <code>dx</code> and <code>dy</code> parameters.
   * @param dx The amount of movement along the <i>x</i> axis to the right, in pixels.
   * @param dy The amount of movement down along the <i>y</i> axis, in pixels.
   *
   * @see http://help.adobe.com/en_US/as3/dev/WS5b3ccc516d4fbf351e63e3d118a9b90204-7ddb.html Using Matrix objects
   *
   */

    public function translate(dx:Float, dy:Float):Void {
        /*
                      [a     c    tx   ]
                      [b     d    ty   ]
                      [0     0    1    ]

      [1     0   dx]  [a     c    tx+dx]
      [0     1   dy]  [b     d    ty+dy]
      [0     0    1]  [0     0    1    ]
    */
        tx += dx;
        ty += dy;
    }

    public function setTo(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Void {
        this.a = a;
        this.b = b;
        this.c = c;
        this.d = d;
        this.tx = tx;
        this.ty = ty;
    }

    // ************************** Jangaroo part **************************

    public function copyFromAndConcat(copyMatrix:Matrix, concatMatrix:Matrix):Void {
        var a1:Float = copyMatrix.a;
        var b1:Float = copyMatrix.b;
        var c1:Float = copyMatrix.c;
        var d1:Float = copyMatrix.d;
        var tx1:Float = copyMatrix.tx;
        var ty1:Float = copyMatrix.ty;

        var a2:Float = concatMatrix.a;
        var b2:Float = concatMatrix.b;
        var c2:Float = concatMatrix.c;
        var d2:Float = concatMatrix.d;
        var tx2:Float = concatMatrix.tx;
        var ty2:Float = concatMatrix.ty;

        a = (a1 * a2 + b1 * c2);
        b = (a1 * b2 + b1 * d2);
        c = (c1 * a2 + d1 * c2);
        d = (c1 * b2 + d1 * d2);
        tx = (tx1 * a2 + ty1 * c2 + tx2);
        ty = (tx1 * b2 + ty1 * d2 + ty2);
    }

    //-------------------------------------------------------------------------------------------------

    public function copyFromAndInvert(matrix:Matrix):Void {
        var a:Float = matrix.a;
        var b:Float = matrix.b;
        var c:Float = matrix.c;
        var d:Float = matrix.d;
        var tx:Float = matrix.tx;
        var ty:Float = matrix.ty;

        var det:Float = a * d - b * c;
        this.a = (d / det);
        this.b = -(b / det);
        this.c = -(c / det);
        this.d = (a / det);
        this.tx = -(this.a * tx + this.c * ty);
        this.ty = -(this.b * tx + this.d * ty);
    }

    /**
   * @private
   */
    public static inline var MAGIC_GRADIENT_FACTOR:Float = 16384 / 10;

    // Adobe's documentation did not make clear how the current matrix has to be multiplied with the transformation
    // matrix.
    // I used http://www.senocular.com/flash/tutorials/transformmatrix/ to find out the implementation
    // that matches Flash 9: multiply transformation matrix with the current matrix, not the other way round.
}
