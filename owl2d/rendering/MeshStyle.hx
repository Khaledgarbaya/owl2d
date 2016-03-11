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
import types.Vector2;
class MeshStyle
{
    /** The vertex format expected by this style (the same as found in the MeshEffect-class). */
    public static const VERTEX_FORMAT:VertexDataFormat = MeshEffect.VERTEX_FORMAT;

    private var _type:Class;
    private var _target:Mesh;
    private var _texture:Texture;
    private var _textureSmoothing:String;
    private var _vertexData:VertexData;   // just a reference to the target's vertex data
    private var _indexData:IndexData;     // just a reference to the target's index data

    // helper objects
    private static var sPoint:Point = new Point();
    public function new()
    {
        _textureSmoothing = TextureSmoothing.BILINEAR;
        _type = cast(Type.getClass(this), Class);
    }
    /** Copies all properties of the given style to the current instance (or a subset, if the
     *  classes don't match). Must be overridden by all subclasses!
     */
    public function copyFrom(meshStyle:MeshStyle):Void
    {
        _texture = meshStyle._texture;
        _textureSmoothing = meshStyle._textureSmoothing;
    }

    /** Creates a clone of this instance. The method will work for subclasses automatically,
     *  no need to override it. */
    public function clone():MeshStyle
    {
        var clone:MeshStyle = new _type();
        clone.copyFrom(this);
        return clone;
    }

    /** Creates the effect that does the actual, low-level rendering.
     *  To be overridden by subclasses!
     */
    public function createEffect():MeshEffect
    {
        return new MeshEffect();
    }

    /** Updates the settings of the given effect to match the current style.
     *  The given <code>effect</code> will always match the class returned by
     *  <code>createEffect</code>.
     *
     *  <p>To be overridden by subclasses!</p>
     */
    public function updateEffect(effect:MeshEffect, state:RenderState):Void
    {
        effect.texture = _texture;
        effect.textureSmoothing = _textureSmoothing;
        effect.mvpMatrix3D = state.mvpMatrix3D;
        effect.alpha = state.alpha;
    }

    /** Indicates if the current instance can be batched with the given style.
     *  To be overridden by subclasses if default behavior is not sufficient.
     *  The base implementation just checks if the styles are of the same type
     *  and if the textures are compatible.
     */
    public function canBatchWith(meshStyle:MeshStyle):Bool
    {
        if (_type == meshStyle._type)
        {
            var newTexture:Texture = meshStyle._texture;

            if (_texture == null && newTexture == null) return true;
            else if (_texture && newTexture)
                return _texture.base == newTexture.base &&
                       _textureSmoothing == meshStyle._textureSmoothing;
            else return false;
        }
        else return false;
    }

    /** Copies the vertex data of the style's current target to the target of another style.
     *  If you pass a matrix, all vertices will be transformed during the process.
     *
     *  <p>This method is used when batching meshes together for rendering. The parameter
     *  <code>targetStyle</code> will point to the style of a <code>MeshBatch</code> (a
     *  subclass of <code>Mesh</code>). Subclasses may override this method if they need
     *  to modify the vertex data in that process.</p>
     */
    public function batchVertexData(targetStyle:MeshStyle, targetVertexID:Int=0,
                                    matrix:Matrix=null, vertexID:Int=0, numVertices:Int=-1):Void
    {
        _vertexData.copyTo(targetStyle._vertexData, targetVertexID, matrix, vertexID, numVertices);
    }

    /** Copies the index data of the style's current target to the target of another style.
     *  The given offset value will be added to all indices during the process.
     *
     *  <p>This method is used when batching meshes together for rendering. The parameter
     *  <code>targetStyle</code> will point to the style of a <code>MeshBatch</code> (a
     *  subclass of <code>Mesh</code>). Subclasses may override this method if they need
     *  to modify the index data in that process.</p>
     */
    public function batchIndexData(targetStyle:MeshStyle, targetIndexID:Int=0, offset:Int=0,
                                   indexID:Int=0, numIndices:Int=-1):Void
    {
        _indexData.copyTo(targetStyle._indexData, targetIndexID, offset, indexID, numIndices);
    }

    /** Call this method if the target needs to be redrawn.
     *  The call is simply forwarded to the mesh. */
    private function setRequiresRedraw():Void
    {
        if (_target) _target.setRequiresRedraw();
    }

    /** Called when assigning a target mesh. Override to plug in class-specific logic. */
    private function onTargetAssigned(target:Mesh):Void
    { }

    // enter frame event

    // override public function addEventListener(type:String, listener:Function):Void
    // {
    //     if (type == Event.ENTER_FRAME && _target)
    //         _target.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    //
    //     super.addEventListener(type, listener);
    // }
    //
    // override public function removeEventListener(type:String, listener:Function):Void
    // {
    //     if (type == Event.ENTER_FRAME && _target)
    //         _target.removeEventListener(type, onEnterFrame);
    //
    //     super.removeEventListener(type, listener);
    // }

    private function onEnterFrame(event:Event):Void
    {
        dispatchEvent(event);
    }

    // internal methods

    /** @private */
    starling_internal function setTarget(target:Mesh=null, vertexData:VertexData=null,
                                         indexData:IndexData=null):Void
    {
        if (_target != target)
        {
            if (_target) _target.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            if (vertexData) vertexData.format = vertexFormat;

            _target = target;
            _vertexData = vertexData;
            _indexData = indexData;

            if (target)
            {
                if (hasEventListener(Event.ENTER_FRAME))
                    target.addEventListener(Event.ENTER_FRAME, onEnterFrame);

                onTargetAssigned(target);
            }
        }
    }

    // vertex manipulation

    /** Returns the alpha value of the vertex at the specified index. */
    public function getVertexAlpha(vertexID:Int):Float
    {
        return _vertexData.getAlpha(vertexID);
    }

    /** Sets the alpha value of the vertex at the specified index to a certain value. */
    public function setVertexAlpha(vertexID:Int, alpha:Float):Void
    {
        _vertexData.setAlpha(vertexID, "color", alpha);
        setRequiresRedraw();
    }

    /** Returns the RGB color of the vertex at the specified index. */
    public function getVertexColor(vertexID:Int):UInt
    {
        return _vertexData.getColor(vertexID);
    }

    /** Sets the RGB color of the vertex at the specified index to a certain value. */
    public function setVertexColor(vertexID:Int, color:UInt):Void
    {
        _vertexData.setColor(vertexID, "color", color);
        setRequiresRedraw();
    }

    /** Returns the texture coordinates of the vertex at the specified index. */
    public function getTexCoords(vertexID:Int, out:Point = null):Point
    {
        if (_texture) return _texture.getTexCoords(_vertexData, vertexID, "texCoords", out);
        else return _vertexData.getPoint(vertexID, "texCoords", out);
    }

    /** Sets the texture coordinates of the vertex at the specified index to the given values. */
    public function setTexCoords(vertexID:Int, u:Float, v:Float):Void
    {
        if (_texture) _texture.setTexCoords(_vertexData, vertexID, "texCoords", u, v);
        else _vertexData.setPoint(vertexID, "texCoords", u, v);

        setRequiresRedraw();
    }

    // properties

    /** Returns a reference to the vertex data of the assigned target (or <code>null</code>
     *  if there is no target). Beware: the style itself does not own any vertices;
     *  it is limited to manipulating those of the target mesh. */
    public var  vertexData(get, null):VertexData;
    private function get vertexData():VertexData { return _vertexData; }

    /** Returns a reference to the index data of the assigned target (or <code>null</code>
     *  if there is no target). Beware: the style itself does not own any indices;
     *  it is limited to manipulating those of the target mesh. */
    public var indexData(get, null):IndexData;
    private function get_indexData():IndexData { return _indexData; }

    /** The actual class of this style. */
    public function get type():Class { return _type; }

    /** Changes the color of all vertices to the same value.
     *  The getter simply returns the color of the first vertex. */
    public var color(get, set): UInt;
    private function get_color():UInt
    {
        if (_vertexData.numVertices > 0) return _vertexData.getColor(0);
        else return 0x0;
    }

    private function set_color(value:UInt):UInt
    {
        var i:Int;
        var numVertices:Int = _vertexData.numVertices;

        for (i=0; i<numVertices; ++i)
            _vertexData.setColor(i, "color", value);

        setRequiresRedraw();
        return value;
    }

    /** The format used to store the vertices. */
    public var  vertexFormat(get,null): VertexDataFormat;
    private function get_vertexFormat():VertexDataFormat
    {
        return VERTEX_FORMAT;
    }

    /** The texture that is mapped to the mesh (or <code>null</code>, if there is none). */
    public var texture(get, set):Texture;
    private function get_texture():Texture { return _texture; }
    private function set_texture(value:Texture):Texture
    {
        if (value != _texture)
        {
            if (value)
            {
                var i:Int;
                var numVertices:Int = _vertexData ? _vertexData.numVertices : 0;

                for (i = 0; i < numVertices; ++i)
                {
                    getTexCoords(i, sPoint);
                    value.setTexCoords(_vertexData, i, "texCoords", sPoint.x, sPoint.y);
                }
            }

            _texture = value;
            setRequiresRedraw();
        }
        return value;
    }

    /** The smoothing filter that is used for the texture. @default bilinear */
    public var textureSmoothing(get, set):String;
    private function get_textureSmoothing():String { return _textureSmoothing; }
    private function set_textureSmoothing(value:String):String
    {
        if (value != _textureSmoothing)
        {
            _textureSmoothing = value;
            setRequiresRedraw();
        }
        return value;
    }

    /** The target the style is currently assigned to. */
    public var target(get, null):Mesh;
    private function get_target():Mesh { return _target; }
}
