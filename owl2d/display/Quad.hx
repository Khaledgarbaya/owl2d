package owl2d.display;
import owl2d.geom.Matrix3D;
import owl2d.geom.Point;
import owl2d.textures.Texture;
import owl2d.rendering.MeshStyle;
import owl2d.rendering.VertexData;
import owl2d.rendering.IndexData;
import owl2d.geom.Matrix;
import types.Vector3;
import owl2d.geom.Rectangle;
class Quad extends Mesh {
    private var _bounds:Rectangle;

    // helper objects
    private static var sPoint3D:Vector3 = new Vector3();
    private static var sMatrix:Matrix = new Matrix();
    private static var sMatrix3D:Matrix3D = new Matrix3D();

    /** Creates a quad with a certain size and color. */

    public function Quad(width:Float, height:Float, color:UInt = 0xffffff) {
        _bounds = new Rectangle(0, 0, width, height);

        var vertexData:VertexData = new VertexData(MeshStyle.VERTEX_FORMAT, 4);
        var indexData:IndexData = new IndexData(6);

        super(vertexData, indexData);

        if (width == 0.0 || height == 0.0)
            throw "Invalid size: width and height must not be zero";

        setupVertices();
        this.color = color;
    }

    /** Sets up vertex- and index-data according to the current settings. */

    private function setupVertices():Void {
        var posAttr:String = "position";
        var texAttr:String = "texCoords";
        var texture:Texture = style.texture;
        var vertexData:VertexData = this.vertexData;
        var indexData:IndexData = this.indexData;

        indexData.numIndices = 0;
        indexData.addQuad(0, 1, 2, 3);
        vertexData.numVertices = 4;
        vertexData.trim();

        if (texture) {
            texture.setupVertexPositions(vertexData, 0, "position", _bounds);
            texture.setupTextureCoordinates(vertexData, 0, texAttr);
        }
        else {
            vertexData.setPoint(0, posAttr, _bounds.left, _bounds.top);
            vertexData.setPoint(1, posAttr, _bounds.right, _bounds.top);
            vertexData.setPoint(2, posAttr, _bounds.left, _bounds.bottom);
            vertexData.setPoint(3, posAttr, _bounds.right, _bounds.bottom);

            vertexData.setPoint(0, texAttr, 0.0, 0.0);
            vertexData.setPoint(1, texAttr, 1.0, 0.0);
            vertexData.setPoint(2, texAttr, 0.0, 1.0);
            vertexData.setPoint(3, texAttr, 1.0, 1.0);
        }

        setRequiresRedraw();
    }

    /** @inheritDoc */

    public override function getBounds(targetSpace:DisplayObject, out:Rectangle = null):Rectangle {
        if (out == null) out = new Rectangle();

        if (targetSpace == this)
        {
            out.copyFrom(_bounds);
        }
        else if (targetSpace == parent && rotation == 0.0)
        {
            var scaleX:Float = this.scaleX;
            var scaleY:Float = this.scaleY;

            out.setTo(x - pivotX * scaleX, y - pivotY * scaleY,
            _bounds.width * scaleX, _bounds.height * scaleY);

            if (scaleX < 0) { out.width *= -1; out.x -= out.width; }
            if (scaleY < 0) { out.height *= -1; out.y -= out.height; }
        }
        else if (is3D && stage)
        {
            stage.getCameraPosition(targetSpace, sPoint3D);
            getTransformationMatrix3D(targetSpace, sMatrix3D);
            RectangleUtil.getBoundsProjected(_bounds, sMatrix3D, sPoint3D, out);
        }
        else
        {
            getTransformationMatrix(targetSpace, sMatrix);
            RectangleUtil.getBounds(_bounds, sMatrix, out);
        }

        return out;
    }

    /** @inheritDoc */

    override public function hitTest(localPoint:Point):DisplayObject
    {
        if (!visible || !touchable || !hitTestMask(localPoint)) return null;
        else if (_bounds.containsPoint(localPoint)) return this;
        else return null;
    }

    /** Readjusts the dimensions of the quad. Use this method without any arguments to
         *  synchronize quad and texture size after assigning a texture with a different size.
         *  You can also force a certain width and height by passing positive, non-zero
         *  values for width and height. */

    public function readjustSize(width:Float = -1, height:Float = -1):Void {
        if (width <= 0) width = texture ? texture.frameWidth : _bounds.width;
        if (height <= 0) height = texture ? texture.frameHeight : _bounds.height;

        if (width != _bounds.width || height != _bounds.height) {
            _bounds.setTo(0, 0, width, height);
            setupVertices();
        }
    }

    /** Creates a quad from the given texture.
         *  The quad will have the same size as the texture. */

    public static function fromTexture(texture:Texture):Quad {
        var quad:Quad = new Quad(100, 100);
        quad.texture = texture;
        quad.readjustSize();
        return quad;
    }

    /** The texture that is mapped to the quad (or <code>null</code>, if there is none).
         *  Per default, it is mapped to the complete quad, i.e. to the complete area between the
         *  top left and bottom right vertices. This can be changed with the
         *  <code>setTexCoords</code>-method.
         *
         *  <p>Note that the size of the quad will not change when you assign a texture, which
         *  means that the texture might be distorted at first. Call <code>readjustSize</code> to
         *  synchronize quad and texture size.</p>
         *
         *  <p>You could also set the texture via the <code>style.texture</code> property.
         *  That way, however, the texture frame won't be taken into account. Since only rectangular
         *  objects can make use of a texture frame, only a property on the Quad class can do that.
         *  </p>
         */

    override private function set_texture(value:Texture):Void {
        if (value != texture) {
            super.texture = value;
            setupVertices();
        }
    }
}
