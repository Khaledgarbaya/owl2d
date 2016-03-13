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
import owl2d.geom.Rectangle;
import owl2d.geom.Matrix;
import haxe.ds.Vector;
import owl2d.rendering.MeshStyle;
import types.Vector2;
import types.Vector3;
class VertexData {
    private var _rawData:Array<Float>;
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
    private static var sHelperPoint:Vector2 = new Vector2();
    private static var sHelperPoint3D:Vector3 = new Vector3();
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

    public function getPoint(vertexID:Int, attrName:String, out:Vector2 = null):Vector2 {
        if (out == null) {
            out = new Vector2();
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

    public function getPoint3D(vertexID:Int, attrName:String, out:Vector3 = null):Vector3 {
        if (out == null) out = new Vector3();

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

    public function getPoint4D(vertexID:Int, attrName:String, out:Vector3 = null):Vector3 {
        if (out == null) out = new Vector3();

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
}
