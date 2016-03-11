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

package owl2d.display;
import owl2d.data.IndexData;
import owl2d.data.VertexData;
class Mesh extends DisplayObject
{
   private static inline var sDefaultStyle:Class = MeshStyle;
   public function new(vertexData:VertexData, indexData:IndexData, )
   {
      if (vertexData == null) throw "VertexData must not be null";
      if (indexData == null)  throw "IndexData must not be null";

      this.vertexData = vertexData;
      this.indexData = indexData;

      setStyle(style, false);
   }

   public function setStyle(meshStyle:MeshStyle=null, mergeWithPredecessor:Bool=true, style:MeshStyle=null):Void
   {
      super();
      if (meshStyle == null) meshStyle = cast(new sDefaultStyle(), MeshStyle);
      else if (meshStyle == style) return;
      else if (meshStyle.target) meshStyle.target.setStyle();

      if (style)
      {
         if (mergeWithPredecessor) meshStyle.copyFrom(style);
         style.setTarget(null);
      }

      style = meshStyle;
      style.setTarget(this, vertexData, indexData);
   }

   /** @inheritDoc */
   override public function dispose():Void
   {
      vertexData.clear();
      indexData.clear();

      super.dispose();
   }

   /** @inheritDoc */
   override public function hitTest(localPoint:Point):DisplayObject
   {
      if (!visible || !touchable || !hitTestMask(localPoint)) return null;
      else return MeshUtil.containsPoint(_vertexData, _indexData, localPoint) ? this : null;
   }

   /** @inheritDoc */
   override public function getBounds(targetSpace:DisplayObject, out:Rectangle=null):Rectangle
   {
      return MeshUtil.calculateBounds(_vertexData, this, targetSpace, out);
   }

   /** @inheritDoc */
   override public function render(painter:Painter):Void
   {
      if (_pixelSnapping)
        snapToPixels(painter.state.modelviewMatrix, painter.pixelSize);

      painter.batchMesh(this);
   }

   private function snapToPixels(matrix:Matrix, pixelSize:Float):Void
   {
      // Snapping only makes sense if the object is unscaled and rotated only by
      // multiples of 90 degrees. If that's the case can be found out by looking
      // at the modelview matrix.

      const E:Float = 0.0001;

      var doSnap:Bool = false;
      var aSq:Float, bSq:Float, cSq:Float, dSq:Float;

      if (matrix.b + E > 0 && matrix.b - E < 0 && matrix.c + E > 0 && matrix.c - E < 0)
      {
        // what we actually want is 'Math.abs(matrix.a)', but squaring
        // the value works just as well for our needs & is faster.

        aSq = matrix.a * matrix.a;
        dSq = matrix.d * matrix.d;
        doSnap = aSq + E > 1 && aSq - E < 1 && dSq + E > 1 && dSq - E < 1;
      }
      else if (matrix.a + E > 0 && matrix.a - E < 0 && matrix.d + E > 0 && matrix.d - E < 0)
      {
        bSq = matrix.b * matrix.b;
        cSq = matrix.c * matrix.c;
        doSnap = bSq + E > 1 && bSq - E < 1 && cSq + E > 1 && cSq - E < 1;
      }

      if (doSnap)
      {
        matrix.tx = Math.round(matrix.tx / pixelSize) * pixelSize;
        matrix.ty = Math.round(matrix.ty / pixelSize) * pixelSize;
      }
   }
   // vertex manipulation

   /** Returns the alpha value of the vertex at the specified index. */
   public function getVertexAlpha(vertexID:Int):Float
   {
      return style.getVertexAlpha(vertexID);
   }

   /** Sets the alpha value of the vertex at the specified index to a certain value. */
   public function setVertexAlpha(vertexID:Int, alpha:Float):Void
   {
      style.setVertexAlpha(vertexID, alpha);
   }

   /** Returns the RGB color of the vertex at the specified index. */
   public function getVertexColor(vertexID:Int):UInt
   {
      return style.getVertexColor(vertexID);
   }

   /** Sets the RGB color of the vertex at the specified index to a certain value. */
   public function setVertexColor(vertexID:Int, color:UInt):Void
   {
      style.setVertexColor(vertexID, color);
   }

   /** Returns the texture coordinates of the vertex at the specified index. */
   public function getTexCoords(vertexID:Int, out:Point = null):Point
   {
      return style.getTexCoords(vertexID, out);
   }

   /** Sets the texture coordinates of the vertex at the specified index to the given values. */
   public function setTexCoords(vertexID:Int, u:Float, v:Float):Void
   {
      style.setTexCoords(vertexID, u, v);
   }

   // properties

   /** The vertex data describing all vertices of the mesh.
   *  Any change requires a call to <code>setRequiresRedraw</code>. */
   public var vertexData(get, null):VertexData;
   private function get_vertexData():VertexData { return _vertexData; }

   /** The index data describing how the vertices are interconnected.
   *  Any change requires a call to <code>setRequiresRedraw</code>. */
   public var indexData(get, null): IndexData;
   private function get_indexData():IndexData { return indexData; }

   /** The style that is used to render the mesh. Styles (which are always subclasses of
   *  <code>MeshStyle</code>) provide a means to completely modify the way a mesh is rendered.
   *  For example, they may add support for color transformations or normal mapping.
   *
   *  <p>The setter will simply forward the assignee to <code>setStyle(value)</code>.</p>
   *
   *  @default MeshStyle
   */
   public var style(get, set):MeshStyle;
   private function get_style():MeshStyle { return style; }
   private function set_style(value:MeshStyle):Class
   {
      setStyle(value);
      return value;
   }

   /** The texture that is mapped to the mesh (or <code>null</code>, if there is none). */
   public var texture(get, set): Texture;
   private function get_texture():Texture { return style.texture; }
   private function set_texture(value:Texture):Void { style.texture = value; return style.texture;}

   /** Changes the color of all vertices to the same value.
   *  The getter simply returns the color of the first vertex. */
   public var color(get, set): UInt;
   private function get_color():UInt { return style.color; }
   private function set_color(value:UInt):UInt { style.color = value; return style.color;}

   /** The smoothing filter that is used for the texture.
   *  @default bilinear */
   public var textureSmoothing(get, set): String;
   private function get_textureSmoothing():String { return style.textureSmoothing; }
   private function set_textureSmoothing(value:String):String { style.textureSmoothing = value; return style.textureSmoothing;}

   /** Controls whether or not the mesh object is snapped to the nearest pixel. This
   *  can prevent the object from looking blurry when it's not exactly aligned with the
   *  pixels of the screen. For this to work, the object must be unscaled and may only
   *  be rotated by multiples of 90 degrees. @default true */
   public var  pixelSnapping(get, set):Bool;
   private function get_pixelSnapping():Bool { return _pixelSnapping; }
   private function set_pixelSnapping(value:Bool):Bool { _pixelSnapping = value; return _pixelSnapping; }

   /** The total number of vertices in the mesh. */
   public function get_numVertices():Int { return _vertexData.numVertices; }

   /** The total number of indices referencing vertices. */
   public function get_numIndices():Int { return _indexData.numIndices; }

   /** The total number of triangles in this mesh.
   *  (In other words: the number of indices divided by three.) */
   public function get_numTriangles():Int { return _indexData.numTriangles; }

   /** The format used to store the vertices. */
   public function get_vertexFormat():VertexDataFormat { return style.vertexFormat; }

   // static properties

   /** The default style used for meshes if no specific style is provided. The default is
   *  <code>starling.rendering.MeshStyle</code>, and any assigned class must be a subclass
   *  of the same. */
   public static function get_defaultStyle():Class { return sDefaultStyle; }
   public static function set_defaultStyle(value:Class):Class
   {
   sDefaultStyle = value;
   return sDefaultStyle;
   }

}
