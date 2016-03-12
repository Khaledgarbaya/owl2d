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

package owl2d.data;
import gl.GLDefines;
import gl.GL;
import types.Data;
class IndexData
{
    /** The number of bytes per index element. */
   private static inline var INDEX_SIZE:Int = 2;

   private var _rawData:Data;
   private var _numIndices:Int;
   private var _initialCapacity:Int;
   private var _useQuadLayout:Bool;

   // helper objects
   private static var sVector:Array<UInt> = [];
   private static var sTrimData:Data = new Data(0);
   private static var sQuadData:Data = new Data(0);


    public function new(initialCapacity: Int = 48)
    {
        _numIndices = 0;
       _initialCapacity = initialCapacity;
       _useQuadLayout = true;
    }

    public function clear(): Void
    {
        if(_rawData != null)
        {
            _rawData.resize(0);
        }
        _numIndices = 0;
        _useQuadLayout = true;
    }

    public function clone(): IndexData
    {
        var clone:IndexData = new IndexData(_numIndices);

        if (!_useQuadLayout)
        {
            clone.switchToGenericData();
            clone._rawData.writeData(_rawData);
        }

        clone._numIndices = _numIndices;
        return clone;
    }
    /** Copies the index data (or a range of it, defined by 'indexID' and 'numIndices')
     *  of this instance to another IndexData object, starting at a certain target index.
     *  If the target is not big enough, it will grow to fit all the new indices.
     *
     *  <p>By passing a non-zero <code>offset</code>, you can raise all copied indices
     *  by that value in the target object.</p>
     */
    public function copyTo(target:IndexData, targetIndexID:Int=0, offset:Int=0,
                           indexID:Int=0, numIndices:Int=-1): Void
    {
        if (numIndices < 0 || indexID + numIndices > _numIndices)
            numIndices = _numIndices - indexID;

        var sourceData:Data, targetData:Data;
        var newNumIndices:Int = targetIndexID + numIndices;

        if (target._numIndices < newNumIndices)
        {
            target._numIndices = newNumIndices;
            ensureQuadDataCapacity(newNumIndices);
        }

        if (_useQuadLayout)
        {
            if (target._useQuadLayout)
            {
                var keepsQuadLayout:Bool = true;
                var distance:Int = targetIndexID - indexID;
                var distanceInQuads:Int = distance / 6;
                var offsetInQuads:Int = offset / 4;

                // This code is executed very often. If it turns out that both IndexData
                // instances use a quad layout, we don't need to do anything here.
                //
                // When "distance / 6 == offset / 4 && distance % 6 == 0 && offset % 4 == 0",
                // the copy operation preserves the quad layout. In that case, we can exit
                // right away. The code below is a little more complex, though, to avoid the
                // (surprisingly costly) mod-operations.

                if (distanceInQuads == offsetInQuads && (offset & 3) == 0 &&
                distanceInQuads * 6 == distance)
                {
                    keepsQuadLayout = true;
                }
                else if (numIndices > 2)
                {
                    keepsQuadLayout = false;
                }
                else
                {
                    for (i in 0...numIndices)
                    {
                        keepsQuadLayout &=
                        getBasicQuadIndexAt(indexID + i) + offset ==
                        getBasicQuadIndexAt(targetIndexID + i);
                    }
                }

                if (keepsQuadLayout) return;
                else target.switchToGenericData();
            }

            sourceData = sQuadData;
            targetData = target._rawData;

            if ((offset & 3) == 0) // => offset % 4 == 0
            {
                indexID += 6 * offset / 4;
                offset = 0;
                ensureQuadDataCapacity(indexID + numIndices);
            }
        }
        else
        {
            if (target._useQuadLayout)
                target.switchToGenericData();

            sourceData = _rawData;
            targetData = target._rawData;
        }

        targetData.offset = targetIndexID * INDEX_SIZE;

        if (offset == 0)
            targetData.writeData(sourceData);
        else
        {
            sourceData.offset = indexID * INDEX_SIZE;

            // by reading junks of 32 instead of 16 bits, we can spare half the time
            while (numIndices > 1)
            {
                var indexAB:UInt = sourceData.readUInt32();
                var indexA:UInt  = ((indexAB & 0xffff0000) >> 16) + offset;
                var indexB:UInt  = ((indexAB & 0x0000ffff)      ) + offset;
                targetData.writeUInt32(indexA << 16 | indexB);
                numIndices -= 2;
            }

            if (numIndices)
                targetData.writeUInt32(sourceData.readUInt32() + offset);
        }
    }
    /** Sets an index at the specified position. */
    public function setIndex(indexID:Int, index:UInt): Void
    {
        if (_numIndices < indexID + 1)
            numIndices = indexID + 1;

        if (_useQuadLayout)
        {
            if (getBasicQuadIndexAt(indexID) == index) return;
            else switchToGenericData();
        }

        _rawData.offset = indexID * INDEX_SIZE;
        _rawData.writeInt16(index);
    }
    /** Reads the index from the specified position. */
    public function getIndex(indexID:Int):Int
    {
        if (_useQuadLayout)
        {
            if (indexID < _numIndices)
                return getBasicQuadIndexAt(indexID);
            else
                throw "EOFError";
        }
        else
        {
            _rawData.offset = indexID * INDEX_SIZE;
            return _rawData.readUInt16();
        }
    }
    /** Adds an offset to all indices in the specified range. */
    public function offsetIndices(offset:Int, indexID:Int=0, numIndices:Int=-1): Void
    {
        if (numIndices < 0 || indexID + numIndices > _numIndices)
        {
            numIndices = _numIndices - indexID;
        }

        var endIndex:Int = indexID + numIndices;

        for (i in indexID...endIndex)
        {
            setIndex(i, getIndex(i) + offset);
        }
    }
    /** Appends three indices representing a triangle. Reference the vertices clockwise,
         *  as this defines the front side of the triangle. */
    public function addTriangle(a:UInt, b:UInt, c:UInt):Void
    {
        if (_useQuadLayout)
        {
            if (a == getBasicQuadIndexAt(_numIndices))
            {
                var oddTriangleID:Bool = (_numIndices & 1) != 0;
                var evenTriangleID:Bool = !oddTriangleID;

                if ((evenTriangleID && b == a + 1 && c == b + 1) ||
                (oddTriangleID && c == a + 1 && b == c + 1))
                {
                    _numIndices += 3;
                    ensureQuadDataCapacity(_numIndices);
                    return;
                }
            }

            switchToGenericData();
        }

        _rawData.offset = _numIndices * INDEX_SIZE;
        _rawData.writeInt16(a);
        _rawData.writeInt16(b);
        _rawData.writeInt16(c);
        _numIndices += 3;
    }
    /** Appends two triangles spawning up the quad with the given indices.
     *  The indices of the vertices are arranged like this:
     *
     *  <pre>
     *  a - b
     *  | / |
     *  c - d
     *  </pre>
     *
     *  <p>To make sure the indices will follow the basic quad layout, make sure each
     *  parameter increments the one before it (e.g. <code>0, 1, 2, 3</code>).</p>
     */
    public function addQuad(a:UInt, b:UInt, c:UInt, d:UInt):Void
    {
        if (_useQuadLayout)
        {
            if (a == getBasicQuadIndexAt(_numIndices) &&
            b == a + 1 && c == b + 1 && d == c + 1)
            {
                _numIndices += 6;
                ensureQuadDataCapacity(_numIndices);
                return;
            }
            else switchToGenericData();
        }

        _rawData.offset = _numIndices * INDEX_SIZE;
        _rawData.writeInt16(a);
        _rawData.writeInt16(b);
        _rawData.writeInt16(c);
        _rawData.writeInt16(b);
        _rawData.writeInt16(d);
        _rawData.writeInt16(c);
        _numIndices += 6;
    }
    /** Creates a vector containing all indices. If you pass an existing vector to the method,
         *  its contents will be overwritten. */
    public function toVector(out:Array<UInt>=null):Array<UInt>
    {
        if (out == null) out = [];
        else out.length = _numIndices;

        var rawData:Data = _useQuadLayout ? sQuadData : _rawData;
        rawData.offset = 0;

        for (i in 0..._numIndices)
        {
            out[i] = rawData.readUInt16();
        }

        return out;
    }
    /** Returns a string representation of the IndexData object,
         *  including a comma-separated list of all indices. */
    public function toString():String
    {
        return "IndexData";
    }

    // private helpers

    private function switchToGenericData():Void
    {
        if (_useQuadLayout)
        {
            _useQuadLayout = false;

            if (_rawData == null)
            {
                _rawData = new Data(0);
                _rawData.allocedLength = _initialCapacity * INDEX_SIZE; // -> allocated memory
                _rawData.offsetLength = _numIndices * INDEX_SIZE;      // -> actual length
            }

            if (_numIndices != 0)
            {
                _rawData.writeData(sQuadData);
            }
        }
    }
    /** Makes sure that the ByteArray containing the normalized, basic quad data contains at
     *  least <code>numIndices</code> indices. The array might grow, but it will never be
     *  made smaller. */
    private function ensureQuadDataCapacity(numIndices:Int):Void
    {
        if (sQuadData.offsetLength >= numIndices * INDEX_SIZE) return;

        var i:Int;
        var oldNumQuads:Int = sQuadData.offsetLength / 12;
        var newNumQuads:Int = Math.ceil(numIndices / 6);

        sQuadData.offset = sQuadData.offsetLength;

        for (i in oldNumQuads...newNumQuads)
        {
            sQuadData.writeInt16(4 * i);
            sQuadData.writeInt16(4 * i + 1);
            sQuadData.writeInt16(4 * i + 2);
            sQuadData.writeInt16(4 * i + 1);
            sQuadData.writeInt16(4 * i + 3);
            sQuadData.writeInt16(4 * i + 2);
        }
    }
    /** Returns the index that's expected at this position if following basic quad layout. */
    private static function getBasicQuadIndexAt(indexID:Int):Int
    {
        var quadID:Int = indexID / 6;
        var posInQuad:Int = indexID - quadID * 6; // => indexID % 6
        var offset:Int;

        if (posInQuad == 0) offset = 0;
        else if (posInQuad == 1 || posInQuad == 3) offset = 1;
        else if (posInQuad == 2 || posInQuad == 5) offset = 2;
        else offset = 3;

        return quadID * 4 + offset;
    }
    // IndexBuffer helpers

    /** Creates an index buffer object with the right size to fit the complete data.
         *  Optionally, the current data is uploaded right away. */
    public function createIndexBuffer(upload:Bool=false,
                                      bufferUsage:GLDefines=null):GLBuffer
    {
        if (_numIndices == 0) return null;
        var buffer: GLBuffer = GL.createBuffer();

        if (upload)
        {
            uploadToIndexBuffer(buffer);
        }
        return buffer;
    }
    /** Uploads the complete data (or a section of it) to the given index buffer. */
    public function uploadToIndexBuffer(buffer:GLBuffer, indexID:Int=0, numIndices:Int=-1, bufferUsage:GLDefines=null):Void
    {
        if (numIndices < 0 || indexID + numIndices > _numIndices)
            numIndices = _numIndices - indexID;

        if(bufferUsage == null)
        {
            bufferUsage = GLDefines.STATIC_DRAW;
        }

        if (numIndices > 0)
        {
            GL.bindBuffer(GLDefines.ELEMENT_ARRAY_BUFFER, buffer);
            GL.bufferData(GLDefines.ELEMENT_ARRAY_BUFFER, _rawData, bufferUsage);
            GL.bindBuffer(GLDefines.ELEMENT_ARRAY_BUFFER, GL.nullBuffer);
        }
    }
    public function trim():Void
    {
        if (_useQuadLayout) return;

        sTrimData.offsetLength = _rawData.offsetLength;
        sTrimData.offset = 0;
        sTrimData.writeData(_rawData);

        _rawData.offsetLength = sTrimData.offsetLength;
        _rawData.writeData(sTrimData);
    }

    public var numIndices(get, set): Int;
    private function get_numIndices():Int { return _numIndices; }
    private function set_numIndices(value:Int):Int
    {
        if (value != _numIndices)
        {
            if (_useQuadLayout) ensureQuadDataCapacity(value);
            else _rawData.offsetLength = value * INDEX_SIZE;
            if (value == 0) _useQuadLayout = true;

            _numIndices = value;
        }
        return _numIndices;
    }

    public var numTriangles(get, set): Int;
    private function get_numTriangles():Int { return _numIndices / 3; }
    private function set_numTriangles(value:Int):Int { numIndices = value * 3; return value;}

    public var numQuads(get, set): Int;
    private function get_numQuads():Int { return _numIndices / 6; }
    private function set_numQuads(value:Int):Int { numIndices = value * 6; return value;}

    public var indexSizeInBytes(get, null): Int;
    private function get_indexSizeInBytes():Int { return INDEX_SIZE; }

    public var useQuadLayout(get, set): Bool;
    private function get_useQuadLayout():Bool { return _useQuadLayout; }
    private function set_useQuadLayout(value:Bool):Bool
    {
        if (value != _useQuadLayout)
        {
            if (value)
            {
                ensureQuadDataCapacity(_numIndices);
                _rawData.offsetLength = 0;
                _useQuadLayout = true;
            }
            else switchToGenericData();
        }
        return value;
    }

    public var rawData(get, null): Data;
    private function get_rawData():Data
    {
        if (_useQuadLayout) return sQuadData;
        else return _rawData;
    }

}
