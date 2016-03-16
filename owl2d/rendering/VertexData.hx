/*
 * Copyright (c) 2011-2015, khaledgarbaya.net | Khaled Garbaya
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
package owl2d.rendering;
import owl2d.geom.Point;
import owl2d.utils.MathUtil;
import owl2d.geom.Vector3D;
import owl2d.geom.Matrix3D;
import types.Data;
import gl.GLBuffer;
import owl2d.utils.MatrixUtil;
import owl2d.geom.Rectangle;
import owl2d.geom.Matrix;
import haxe.ds.Vector;
import owl2d.rendering.MeshStyle;
class VertexData {
    private var _rawData:Data;
    private var _numVertices:Int;
    private var _format:VertexDataFormat;
    private var _attributes:Array<VertexDataAttribute>;
    private var _numAttributes:Int;
    private var _premultipliedAlpha:Bool;

    private var _posOffset:Int;
    private var _colOffset:Int;
    private var _vertexSize:Int;

    private static inline var MIN_ALPHA:Float = 0.001;
    private static inline var MAX_ALPHA:Float = 1.0;

    // helper objects
    private static var sHelperPoint:Point = new Point();
    private static var sHelperPoint3D:Vector3D = new Vector3D();
    private static var sData:Array<Float> = [];

    public function new(format:Dynamic = null, initialCapacity:Int = 4) {
        if (format == null) {
            _format = MeshStyle.VERTEX_FORMAT;
        }
        else if (Std.is(format, VertexDataFormat)) {
            _format = format;
        }
        else if (Std.is(format, String)) {
            _format = VertexDataFormat.fromString(cast(format, String));
        }
        else {
            throw "'format' must be String or VertexDataFormat";
        }

        _rawData = new Vector<Float>(initialCapacity * _format.vertexSize);
        _attributes = _format.attributes;
        _numAttributes = _attributes.length;
        _posOffset = _format.hasAttribute("position") ? _format.getOffset("position") : 0;
        _colOffset = _format.hasAttribute("color") ? _format.getOffset("color") : 0;
        _vertexSize = _format.vertexSize;
        _numVertices = 0;
        _premultipliedAlpha = true;
    }

    public function clear():Void {
        _rawData.length = 0;
        _numVertices = 0;
    }

    public function clone():VertexData {
        var clone:VertexData = new VertexData(_format);
        clone._rawData = _rawData.slice();
        clone._numVertices = _numVertices;
        clone._premultipliedAlpha = _premultipliedAlpha;
        return clone;
    }

    public function copyTo(target:VertexData, targetVertexID:Int = 0, matrix:Matrix = null,
                           vertexID:Int = 0, numVertices:Int = -1):Void {
        if (numVertices < 0 || vertexID + numVertices > _numVertices)
            numVertices = _numVertices - vertexID;

        if (_format == target._format) {
            if (target._numVertices < targetVertexID + numVertices)
                target._numVertices = targetVertexID + numVertices;

            var i:Int, x:Float, y:Float;
            var targetData:Array<Float> = target._rawData;
            var targetPos:Int = targetVertexID * _vertexSize;
            var sourcePos:Int = vertexID * _vertexSize;
            var sourceEnd:Int = (vertexID + numVertices) * _vertexSize;

            if (matrix) {
                // copy everything before 'position'
                for (i in 0..._posOffset) {
                    targetData[targetPos++] = _rawData[sourcePos++];
                }

                while (sourcePos < sourceEnd) {
                    x = _rawData[sourcePos++];
                    y = _rawData[sourcePos++];

                    targetData[targetPos++] = matrix.a * x + matrix.c * y + matrix.tx;
                    targetData[targetPos++] = matrix.d * y + matrix.b * x + matrix.ty;

                    for (i in 2..._vertexSize) {
                        targetData[targetPos++] = _rawData[sourcePos++];
                    }
                }
            }
            else {
                while (sourcePos < sourceEnd)
                    targetData[targetPos++] = _rawData[sourcePos++];
            }
        }
        else {
            if (target._numVertices < targetVertexID + numVertices)
                target.numVertices = targetVertexID + numVertices; // ensure correct alphas!

            for (i in 0..._numAttributes) {
                var srcAttr:VertexDataAttribute = _attributes[i];
                var tgtAttr:VertexDataAttribute = target.getAttribute(srcAttr.name);

                if (tgtAttr) // only copy attributes that exist in the target, as well {
                if (srcAttr.offset == _posOffset)
                    copyAttributeTo_internal(target, targetVertexID, matrix,
                    srcAttr, tgtAttr, vertexID, numVertices);
                else
                    copyAttributeTo_internal(target, targetVertexID, null,
                    srcAttr, tgtAttr, vertexID, numVertices);
            }
        }
    }

    public function copyAttributeTo(target:VertexData, targetVertexID:Int, attrName:String,
                                    matrix:Matrix = null, vertexID:Int = 0, numVertices:Int = -1):Void {
        var sourceAttribute:VertexDataAttribute = getAttribute(attrName);
        var targetAttribute:VertexDataAttribute = target.getAttribute(attrName);

        if (sourceAttribute == null)
            throw "Attribute '" + attrName + "' not found in source data";

        if (targetAttribute == null)
            throw "Attribute '" + attrName + "' not found in target data";

        copyAttributeTo_internal(target, targetVertexID, matrix,
        sourceAttribute, targetAttribute, vertexID, numVertices);
    }

    private function copyAttributeTo_internal(
        target:VertexData, targetVertexID:Int, matrix:Matrix,
        sourceAttribute:VertexDataAttribute, targetAttribute:VertexDataAttribute,
        vertexID:Int, numVertices:Int):Void {
        if (sourceAttribute.format != targetAttribute.format)
            throw "Attribute formats differ between source and target";

        if (numVertices < 0 || vertexID + numVertices > _numVertices)
            numVertices = _numVertices - vertexID;

        if (target._numVertices < targetVertexID + numVertices)
            target._numVertices = targetVertexID + numVertices;

        var i:Int, j:Int, x:Float, y:Float;
        var attributeSize:Int = sourceAttribute.size;
        var sourceData:Array<Float> = _rawData;
        var targetData:Array<Float> = target._rawData;
        var sourceDelta:Int = _vertexSize - attributeSize;
        var targetDelta:Int = target._vertexSize - attributeSize;
        var sourcePos:Int = vertexID * _vertexSize + sourceAttribute.offset;
        var targetPos:Int = targetVertexID * target._vertexSize + targetAttribute.offset;

        if (matrix) {
            for (i in 0...numVertices) {
                x = sourceData[sourcePos++];
                y = sourceData[sourcePos++];

                targetData[targetPos++] = matrix.a * x + matrix.c * y + matrix.tx;
                targetData[targetPos++] = matrix.d * y + matrix.b * x + matrix.ty;

                sourcePos += sourceDelta;
                targetPos += targetDelta;
            }
        }
        else {
            for (i in 0...numVertices) {
                for (j in 0...attributeSize)
                    targetData[targetPos++] = sourceData[sourcePos++];

                sourcePos += sourceDelta;
                targetPos += targetDelta;
            }
        }
    }

    public function trim():Void {
        _rawData.length = _vertexSize * _numVertices;
    }

    public function toString():String {
        return '[VertexData format="${_format.formatString}" numVertices=$_numVertices]';
    }
    /** Reads a float value from the specified vertex and attribute. */

    public function getFloat(vertexID:Int, attrName:String):Float {
        return _rawData[Int(vertexID * _vertexSize + getAttribute(attrName).offset)];
    }

    /** Writes a float value to the specified vertex and attribute. */

    public function setFloat(vertexID:Int, attrName:String, value:Float):Void {
        if (_numVertices < vertexID + 1) {
            numVertices = vertexID + 1;
        }

        _rawData[Int(vertexID * _vertexSize + getAttribute(attrName).offset)] = value;
    }
    /** Reads a Vector2 from the specified vertex and attribute. */

    public function getPoint(vertexID:Int, attrName:String, out:Point = null):Point {
        if (out == null) {
            out = new Point();
        }

        var offset:Int = attrName == "position" ? _posOffset : getAttribute(attrName).offset;
        var pos:Int = vertexID * _vertexSize + offset;
        out.x = _rawData[pos];
        out.y = _rawData[Int(pos + 1)];

        return out;
    }

    /** Writes the given coordinates to the specified vertex and attribute. */

    public function setPoint(vertexID:Int, attrName:String, x:Float, y:Float):Void {
        if (_numVertices < vertexID + 1) {
            numVertices = vertexID + 1;
        }

        var offset:Int = attrName == "position" ? _posOffset : getAttribute(attrName).offset;
        var pos:Int = vertexID * _vertexSize + offset;
        _rawData[pos] = x;
        _rawData[Int(pos + 1)] = y;
    }
    /** Reads a Vector3 from the specified vertex and attribute.
    *  The 'w' property of the Vector3 is ignored. */

    public function getPoint3D(vertexID:Int, attrName:String, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();

        var pos:Int = vertexID * _vertexSize + getAttribute(attrName).offset;
        out.x = _rawData[pos];
        out.y = _rawData[Int(pos + 1)];
        out.z = _rawData[Int(pos + 2)];

        return out;
    }

    /** Writes the given coordinates to the specified vertex and attribute. */

    public function setPoint3D(vertexID:Int, attrName:String, x:Float, y:Float, z:Float):Void {
        if (_numVertices < vertexID + 1)
            numVertices = vertexID + 1;

        var pos:Int = vertexID * _vertexSize + getAttribute(attrName).offset;
        _rawData[pos] = x;
        _rawData[Int(pos + 1)] = y;
        _rawData[Int(pos + 2)] = z;
    }
    /** Reads a Vector3 from the specified vertex and attribute, including the fourth
    *  coordinate ('w'). */

    public function getPoint4D(vertexID:Int, attrName:String, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();

        var pos:Int = vertexID * _vertexSize + getAttribute(attrName).offset;
        out.x = _rawData[pos];
        out.y = _rawData[Int(pos + 1)];
        out.z = _rawData[Int(pos + 2)];
        out.w = _rawData[Int(pos + 3)];

        return out;
    }

    /** Writes the given coordinates to the specified vertex and attribute. */

    public function setPoint4D(vertexID:Int, attrName:String,
                               x:Float, y:Float, z:Float, w:Float = 1.0):Void {
        if (_numVertices < vertexID + 1)
            numVertices = vertexID + 1;

        var pos:Int = vertexID * _vertexSize + getAttribute(attrName).offset;
        _rawData[pos] = x;
        _rawData[Int(pos + 1)] = y;
        _rawData[Int(pos + 2)] = z;
        _rawData[Int(pos + 3)] = w;
    }
    /** Reads an RGB color from the specified vertex and attribute (no alpha). */

    public function getColor(vertexID:Int, attrName:String = "color"):UInt {
        var offset:Int = attrName == "color" ? _colOffset : getAttribute(attrName).offset;
        var pos:Int = vertexID * _vertexSize + offset;
        var divisor:Float = _premultipliedAlpha ? _rawData[Int(pos + 3)] : 1.0;

        if (divisor == 0) return 0;
        else {
            var red:Float = _rawData[pos] / divisor;
            var green:Float = _rawData[Int(pos + 1)] / divisor;
            var blue:Float = _rawData[Int(pos + 2)] / divisor;

            return (Int(red * 255) << 16) | (Int(green * 255) << 8) | Int(blue * 255);
        }
    }

    /** Writes the RGB color to the specified vertex and attribute (alpha is not changed). */

    public function setColor(vertexID:Int, attrName:String, color:UInt):Void {
        if (_numVertices < vertexID + 1)
            numVertices = vertexID + 1;

        var offset:Int = attrName == "color" ? _colOffset : getAttribute(attrName).offset;
        var pos:Int = vertexID * _vertexSize + offset;
        var multiplier:Float = _premultipliedAlpha ? _rawData[Int(pos + 3)] : 1.0;

        _rawData[pos] = ((color >> 16) & 0xff) / 255.0 * multiplier;
        _rawData[Int(pos + 1)] = ((color >> 8) & 0xff) / 255.0 * multiplier;
        _rawData[Int(pos + 2)] = ( color & 0xff) / 255.0 * multiplier;
    }

    /** Reads the alpha value from the specified vertex and attribute. */

    public function getAlpha(vertexID:Int, attrName:String = "color"):Float {
        var offset:Int = attrName == "color" ? _colOffset : getAttribute(attrName).offset;
        var pos:Int = vertexID * _vertexSize + offset + 3;

        return _rawData[pos];
    }

    /** Writes the given alpha value to the specified vertex and attribute (range 0-1). */

    public function setAlpha(vertexID:Int, attrName:String, alpha:Float):Void {
        if (_numVertices < vertexID + 1)
            numVertices = vertexID + 1;

        var color:UInt = getColor(vertexID, attrName);
        colorize(attrName, color, alpha, vertexID, 1);
    }
    // bounds helpers

    /** Calculates the bounds of the 2D vertex positions identified by the given name.
         *  The positions may optionally be transformed by a matrix before calculating the bounds.
         *  If you pass an 'out' Rectangle, the result will be stored in this rectangle
         *  instead of creating a Owl2d object. To use all vertices for the calculation, set
         *  'numVertices' to '-1'. */

    public function getBounds(attrName:String = "position", matrix:Matrix = null,
                              vertexID:Int = 0, numVertices:Int = -1, out:Rectangle = null):Rectangle {
        if (out == null) out = new Rectangle();
        if (numVertices < 0 || vertexID + numVertices > _numVertices)
            numVertices = _numVertices - vertexID;

        if (numVertices == 0) {
            if (matrix == null)
                out.setEmpty();
            else {
                MatrixUtil.transformCoords(matrix, 0, 0, sHelperPoint);
                out.setTo(sHelperPoint.x, sHelperPoint.y, 0, 0);
            }
        }
        else {
            var minX:Float = Math.POSITIVE_INFINITY, maxX:Float = -Math.POSITIVE_INFINITY;
            var minY:Float = Math.POSITIVE_INFINITY, maxY:Float = -Math.POSITIVE_INFINITY;
            var offset:Int = attrName == "position" ? _posOffset : getAttribute(attrName).offset;
            var position:Int = vertexID * _vertexSize + offset;
            var x:Float, y:Float, i:Int;

            if (matrix == null) {
                for (i in 0...numVertices) {
                    x = _rawData[position];
                    y = _rawData[Int(position + 1)];
                    position += _vertexSize;

                    if (minX > x) minX = x;
                    if (maxX < x) maxX = x;
                    if (minY > y) minY = y;
                    if (maxY < y) maxY = y;
                }
            }
            else {
                for (i in 0...numVertices) {
                    x = _rawData[position];
                    y = _rawData[Int(position + 1)];
                    position += _vertexSize;

                    MatrixUtil.transformCoords(matrix, x, y, sHelperPoint);

                    if (minX > sHelperPoint.x) minX = sHelperPoint.x;
                    if (maxX < sHelperPoint.x) maxX = sHelperPoint.x;
                    if (minY > sHelperPoint.y) minY = sHelperPoint.y;
                    if (maxY < sHelperPoint.y) maxY = sHelperPoint.y;
                }
            }

            out.setTo(minX, minY, maxX - minX, maxY - minY);
        }

        return out;
    }

    /** Calculates the bounds of the 2D vertex positions identified by the given name,
     *  projected into the XY-plane of a certain 3D space as they appear from the given
     *  camera position. Note that 'camPos' is expected in the target coordinate system
     *  (the same that the XY-plane lies in).
     *
     *  <p>If you pass an 'out' Rectangle, the result will be stored in this rectangle
     *  instead of creating a new object. To use all vertices for the calculation, set
     *  'numVertices' to '-1'.</p> */

    public function getBoundsProjected(attrName:String, matrix:Matrix3D,
                                       camPos:Vector3D, vertexID:Int = 0, numVertices:Int = -1,
                                       out:Rectangle = null):Rectangle {
        if (out == null) out = new Rectangle();
        if (camPos == null) throw "camPos must not be null";
        if (numVertices < 0 || vertexID + numVertices > _numVertices)
            numVertices = _numVertices - vertexID;

        if (numVertices == 0) {
            if (matrix)
                MatrixUtil.transformCoords3D(matrix, 0, 0, 0, sHelperPoint3D);
            else
                sHelperPoint3D.setTo(0, 0, 0);

            MathUtil.intersectLineWithXYPlane(camPos, sHelperPoint3D, sHelperPoint);
            out.setTo(sHelperPoint.x, sHelperPoint.y, 0, 0);
        }
        else {
            var minX:Float = Float.MAX_VALUE, maxX:Float = -Float.MAX_VALUE;
            var minY:Float = Float.MAX_VALUE, maxY:Float = -Float.MAX_VALUE;
            var offset:Int = attrName == "position" ? _posOffset : getAttribute(attrName).offset;
            var position:Int = vertexID * _vertexSize + offset;
            var x:Float, y:Float, i:Int;

            for (i in 0...numVertices) {
                _rawData.position = position;
                x = _rawData.readFloat();
                y = _rawData.readFloat();
                position += _vertexSize;

                if (matrix)
                    MatrixUtil.transformCoords3D(matrix, x, y, 0, sHelperPoint3D);
                else
                    sHelperPoint3D.setTo(x, y, 0);

                MathUtil.intersectLineWithXYPlane(camPos, sHelperPoint3D, sHelperPoint);

                if (minX > sHelperPoint.x) minX = sHelperPoint.x;
                if (maxX < sHelperPoint.x) maxX = sHelperPoint.x;
                if (minY > sHelperPoint.y) minY = sHelperPoint.y;
                if (maxY < sHelperPoint.y) maxY = sHelperPoint.y;
            }

            out.setTo(minX, minY, maxX - minX, maxY - minY);
        }

        return out;
    }

    /** Indicates if color attributes should be stored premultiplied with the alpha value.
         *  Changing this value does <strong>not</strong> modify any existing color data.
         *  If you want that, use the <code>setPremultipliedAlpha</code> method instead.
         *  @default true */
    public var premultipliedAlpha(get, set):Bool;

    private function get_premultipliedAlpha():Bool { return _premultipliedAlpha; }

    private function set_premultipliedAlpha(value:Bool):Bool {
        setPremultipliedAlpha(value, false);
        return value;
    }

    /** Changes the way alpha and color values are stored. Optionally updates all existing
         *  vertices. */

    public function setPremultipliedAlpha(value:Bool, updateData:Bool):Void {
        if (updateData && value != _premultipliedAlpha) {
            for (i in 0..._numAttributes) {
                var attribute:VertexDataAttribute = _attributes[i];
                if (attribute.isColor) {
                    var pos:Int = attribute.offset;
                    var oldColor:UInt;
                    var newColor:UInt;

                    for (j in 0..._numVertices) {
                        _rawData.position = pos;
                        oldColor = switchEndian(_rawData.readUnsignedInt());
                        newColor = value ? premultiplyAlpha(oldColor) : unmultiplyAlpha(oldColor);

                        _rawData.position = pos;
                        _rawData.writeUnsignedInt(switchEndian(newColor));

                        pos += _vertexSize;
                    }
                }
            }
        }

        _premultipliedAlpha = value;
    }

    /** Updates the <code>tinted</code> property from the actual color data. This might make
         *  sense after copying part of a tinted VertexData instance to another, since not each
         *  color value is checked in the process. An instance is tinted if any vertices have a
         *  non-white color or are not fully opaque. */

    public function updateTinted(attrName:String = "color"):Bool {
        //TODOmatch Data api
        var pos:Int = attrName == "color" ? _colOffset : getAttribute(attrName).offset;
        _tinted = false;

        for (i in 0..._numVertices) {
            _rawData.position = pos;

            if (_rawData.readUnsignedInt() != 0xffffffff) {
                _tinted = true;
                break;
            }

            pos += _vertexSize;
        }

        return _tinted;
    }

    // modify multiple attributes

    /** Transforms the 2D positions of subsequent vertices by multiplication with a
         *  transformation matrix. */

    public function transformPoints(attrName:String, matrix:Matrix,
                                    vertexID:Int = 0, numVertices:Int = -1):Void {
        if (numVertices < 0 || vertexID + numVertices > _numVertices)
            numVertices = _numVertices - vertexID;

        var x:Float, y:Float;
        var offset:Int = attrName == "position" ? _posOffset : getAttribute(attrName).offset;
        var pos:Int = vertexID * _vertexSize + offset;
        var endPos:Int = pos + numVertices * _vertexSize;

        while (pos < endPos) {
            _rawData.position = pos;
            x = _rawData.readFloat();
            y = _rawData.readFloat();

            _rawData.position = pos;
            _rawData.writeFloat(matrix.a * x + matrix.c * y + matrix.tx);
            _rawData.writeFloat(matrix.d * y + matrix.b * x + matrix.ty);

            pos += _vertexSize;
        }
    }

    /** Translates the 2D positions of subsequent vertices by a certain offset. */

    public function translatePoints(attrName:String, deltaX:Float, deltaY:Float,
                                    vertexID:Int = 0, numVertices:Int = -1):Void {
        if (numVertices < 0 || vertexID + numVertices > _numVertices)
            numVertices = _numVertices - vertexID;

        var x:Float, y:Float;
        var offset:Int = attrName == "position" ? _posOffset : getAttribute(attrName).offset;
        var pos:Int = vertexID * _vertexSize + offset;
        var endPos:Int = pos + numVertices * _vertexSize;

        while (pos < endPos) {
            _rawData.position = pos;
            x = _rawData.readFloat();
            y = _rawData.readFloat();

            _rawData.position = pos;
            _rawData.writeFloat(x + deltaX);
            _rawData.writeFloat(y + deltaY);

            pos += _vertexSize;
        }
    }

    /** Multiplies the alpha values of subsequent vertices by a certain factor. */

    public function scaleAlphas(attrName:String, factor:Float,
                                vertexID:Int = 0, numVertices:Int = -1):Void {
        if (factor == 1.0) return;
        if (numVertices < 0 || vertexID + numVertices > _numVertices)
            numVertices = _numVertices - vertexID;

        _tinted = true; // factor must be != 1, so there's definitely tinting.

        var i:Int;
        var offset:Int = attrName == "color" ? _colOffset : getAttribute(attrName).offset;
        var colorPos:Int = vertexID * _vertexSize + offset;
        var alphaPos:Int, alpha:Float, rgba:UInt;

        for (i in 0...numVertices) {
            alphaPos = colorPos + 3;
            alpha = _rawData[alphaPos] / 255.0 * factor;

            if (alpha > 1.0) alpha = 1.0;
            else if (alpha < 0.0) alpha = 0.0;

            if (alpha == 1.0 || !_premultipliedAlpha) {
                _rawData[alphaPos] = Int(alpha * 255.0);
            }
            else {
                _rawData.position = colorPos;
                rgba = unmultiplyAlpha(switchEndian(_rawData.readUnsignedInt()));
                rgba = (rgba & 0xffffff00) | (Int(alpha * 255.0) & 0xff);
                rgba = premultiplyAlpha(rgba);

                _rawData.position = colorPos;
                _rawData.writeUnsignedInt(switchEndian(rgba));
            }

            colorPos += _vertexSize;
        }
    }

    /** Writes the given RGB and alpha values to the specified vertices. */

    public function colorize(attrName:String = "color", color:UInt = 0xffffff, alpha:Float = 1.0,
                             vertexID:Int = 0, numVertices:Int = -1):Void {
        if (numVertices < 0 || vertexID + numVertices > _numVertices)
            numVertices = _numVertices - vertexID;

        var offset:Int = attrName == "color" ? _colOffset : getAttribute(attrName).offset;
        var pos:Int = vertexID * _vertexSize + offset;
        var endPos:Int = pos + (numVertices * _vertexSize);

        if (alpha > 1.0) alpha = 1.0;
        else if (alpha < 0.0) alpha = 0.0;

        var rgba:UInt = ((color << 8) & 0xffffff00) | (Int(alpha * 255.0) & 0xff);

        if (rgba == 0xffffffff && numVertices == _numVertices) _tinted = false;
        else if (rgba != 0xffffffff) _tinted = true;

        if (_premultipliedAlpha && alpha != 1.0) rgba = premultiplyAlpha(rgba);

        _rawData.position = vertexID * _vertexSize + offset;
        _rawData.writeUnsignedInt(switchEndian(rgba));

        while (pos < endPos) {
            _rawData.position = pos;
            _rawData.writeUnsignedInt(switchEndian(rgba));
            pos += _vertexSize;
        }
    }

    // format helpers

    /** Returns the format of a certain vertex attribute, identified by its name.
          * Typical values: <code>float1, float2, float3, float4, bytes4</code>. */

    public function getFormat(attrName:String):String {
        return getAttribute(attrName).format;
    }

    /** Returns the size of a certain vertex attribute in bytes. */

    public function getSize(attrName:String):Int {
        return getAttribute(attrName).size;
    }

    /** Returns the size of a certain vertex attribute in 32 bit units. */

    public function getSizeIn32Bits(attrName:String):Int {
        return getAttribute(attrName).size / 4;
    }

    /** Returns the offset (in bytes) of an attribute within a vertex. */

    public function getOffset(attrName:String):Int {
        return getAttribute(attrName).offset;
    }

    /** Returns the offset (in 32 bit units) of an attribute within a vertex. */

    public function getOffsetIn32Bits(attrName:String):Int {
        return getAttribute(attrName).offset / 4;
    }

    /** Indicates if the VertexData instances contains an attribute with the specified name. */

    public function hasAttribute(attrName:String):Bool {
        return getAttribute(attrName) != null;
    }

    // VertexBuffer helpers

    /** Creates a vertex buffer object with the right size to fit the complete data.
         *  Optionally, the current data is uploaded right away. */

    public function createVertexBuffer(upload:Bool = false,
                                       bufferUsage:String = "staticDraw"):GLBuffer {
//        if (context == null) throw new MissingContextError();
//        if (_numVertices == 0) return null;
//
//        var buffer:GLBuffer =
//
//        context.createVertexBuffer(
//            _numVertices, _vertexSize / 4, bufferUsage);
//
//        if (upload) uploadToVertexBuffer(buffer);
//
//
//
//        return buffer;
        return null;
    }

    /** Uploads the complete data (or a section of it) to the given vertex buffer. */

    public function uploadToVertexBuffer(buffer:GLBuffer, vertexID:Int = 0, numVertices:Int = -1):Void {
//        if (numVertices < 0 || vertexID + numVertices > _numVertices)
//            numVertices = _numVertices - vertexID;
//
//        if (numVertices > 0)
//            buffer.uploadFromByteArray(_rawData, 0, vertexID, numVertices);
        //TODO Change it to the opengl way
    }

    private inline function getAttribute(attrName:String):VertexDataAttribute {
        var i:Int, attribute:VertexDataAttribute;

        for (i in 0..._numAttributes) {
            attribute = _attributes[i];
            if (attribute.name == attrName) return attribute;
        }

        return null;
    }

    private static inline function switchEndian(value:UInt):UInt {
        return ( value & 0xff) << 24 |
        ((value >> 8) & 0xff) << 16 |
        ((value >> 16) & 0xff) << 8 |
        ((value >> 24) & 0xff);
    }

    private static function premultiplyAlpha(rgba:UInt):UInt {
        var alpha:UInt = rgba & 0xff;

        if (alpha == 0xff) return rgba;
        else {
            var factor:Float = alpha / 255.0;
            var r:UInt = ((rgba >> 24) & 0xff) * factor;
            var g:UInt = ((rgba >> 16) & 0xff) * factor;
            var b:UInt = ((rgba >> 8) & 0xff) * factor;

            return (r & 0xff) << 24 |
            (g & 0xff) << 16 |
            (b & 0xff) << 8 | alpha;
        }
    }

    private static function unmultiplyAlpha(rgba:UInt):UInt {
        var alpha:UInt = rgba & 0xff;

        if (alpha == 0xff || alpha == 0x0) return rgba;
        else {
            var factor:Float = alpha / 255.0;
            var r:UInt = ((rgba >> 24) & 0xff) / factor;
            var g:UInt = ((rgba >> 16) & 0xff) / factor;
            var b:UInt = ((rgba >> 8) & 0xff) / factor;

            return (r & 0xff) << 24 |
            (g & 0xff) << 16 |
            (b & 0xff) << 8 | alpha;
        }
    }

    // properties

/** The total Float of vertices. If you make the object bigger, it will be filled up with
*  <code>1.0</code> for all alpha values and zero for everything else. */
    public var numVertices(get, set):Int;

    public function get_numVertices():Int { return _numVertices; }

    public function set_numVertices(value:Int):Int {
        if (value > _numVertices) {
            var oldLength:Int = _numVertices * vertexSize;
            var newLength:Int = value * _vertexSize;

            if (_rawData.length > oldLength) {
                _rawData.position = oldLength;
                while (_rawData.bytesAvailable) _rawData.writeUnsignedInt(0);
            }

            if (_rawData.length < newLength)
                _rawData.length = newLength;

            for (i in 0..._numAttributes) {
                var attribute:VertexDataAttribute = _attributes[i];
                if (attribute.isColor) { // initialize color values with "white" and full alpha
                    var pos:Int = _numVertices * _vertexSize + attribute.offset;

                    for (j in _numVertices...value) {
                        _rawData.position = pos;
                        _rawData.writeUnsignedInt(0xffffffff);
                        pos += _vertexSize;
                    }
                }
            }
        }

        if (value == 0) _tinted = false;
        _numVertices = value;
        return _numVertices;
    }
/** The raw vertex data; not a copy! */
    public var rawData(get, null):Data;

    private function get_rawData():Data {
        return _rawData;
    }

/** The format that describes the attributes of each vertex.
 *  When you assign a different format, the raw data will be converted accordingly,
 *  i.e. attributes with the same name will still point to the same data.
 *  New properties will be filled up with zeros (except for colors, which will be
 *  initialized with an alpha value of 1.0). As a side-effect, the instance will also
 *  be trimmed. */
    public var format(get, set):VertexDataFormat;

    public function get_format():VertexDataFormat {
        return _format;
    }

    public function set_format(value:VertexDataFormat):VertexDataFormat {
        if (_format == value) return value;

        var pos:Int;
        var srcVertexSize:Int = _format.vertexSize;
        var tgtVertexSize:Int = value.vertexSize;
        var numAttributes:Int = value.numAttributes;

        sBytes.length = value.vertexSize * _numVertices;

        for (a in 0...numAttributes) {
            var tgtAttr:VertexDataAttribute = value.attributes[a];
            var srcAttr:VertexDataAttribute = getAttribute(tgtAttr.name);

            if (srcAttr) { // copy attributes that exist in both targets
                pos = tgtAttr.offset;

                for (i in 0..._numVertices) {
                    sBytes.position = pos;
                    sBytes.writeBytes(_rawData, srcVertexSize * i + srcAttr.offset, srcAttr.size);
                    pos += tgtVertexSize;
                }
            }
            else if (tgtAttr.isColor) { // initialize color values with "white" and full alpha
                pos = tgtAttr.offset;

                for (i in 0..._numVertices) {
                    sBytes.position = pos;
                    sBytes.writeUnsignedInt(0xffffffff);
                    pos += tgtVertexSize;
                }
            }
        }

        _rawData.clear();
        _rawData.length = sBytes.length;
        _rawData.writeBytes(sBytes);
        sBytes.clear();

        _format = value;
        _attributes = _format.attributes;
        _numAttributes = _attributes.length;
        _vertexSize = _format.vertexSize;
        _posOffset = _format.hasAttribute("position") ? _format.getOffset("position") : 0;
        _colOffset = _format.hasAttribute("color") ? _format.getOffset("color") : 0;

        return _format;
    }

/** Indicates if the mesh contains any vertices that are not white or not fully opaque.
 *  If <code>false</code> (and the value wasn't modified manually), the result is 100%
 *  accurate; <code>true</code> represents just an educated guess. To be entirely sure,
 *  you may call <code>updateTinted()</code>.
 */
    public var tinted(get, set):Bool;

    private function get_tinted():Bool { return _tinted; }

    private function set_tinted(value:Bool):Bool { _tinted = value; return value;}

/** The format string that describes the attributes of each vertex. */
    public var formatString(get, null):String;

    private function get_formatString():String {
        return _format.formatString;
    }

/** The size (in bytes) of each vertex. */
    public var vertexSize(get, null):Int;

    private function get_vertexSize():Int {
        return _vertexSize;
    }

/** The size (in 32 bit units) of each vertex. */
    public var vertexSizeIn32Bits(get, null):Int;

    private function get_vertexSizeIn32Bits():Int {
        return _vertexSize / 4;
    }
/** The size (in bytes) of the raw vertex data. */
    public var size(get, null):Int;

    private function get_size():Int {
        return _numVertices * _vertexSize;
    }
/** The size (in 32 bit units) of the raw vertex data. */
    public var sizeIn32Bits(get, null):Int;

    private function get_sizeIn32Bits():Int {
        return _numVertices * _vertexSize / 4;
    }
}
