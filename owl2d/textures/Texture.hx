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

package owl2d.textures;
import gl.GLDefines;
import owl2d.utils.MatrixUtil;
import owl2d.rendering.VertexData;
import flash.display3D.textures.RectangleTexture;
import owl2d.utils.MathUtil;
import jpg.Data;
import owl2d.geom.Point;
import flash.geom.Matrix;
import owl2d.geom.Rectangle;
import gl.GLTexture;
class Texture
{
// helper objects
    private static var sDefaultOptions:TextureOptions = new TextureOptions();
    private static var sRectangle:Rectangle = new Rectangle();
    private static var sMatrix:Matrix = new Matrix();
    private static var sPoint:Point = new Point();

    /** @private */
    private function new()
    {
    }

    /** Disposes the underlying texture data. Note that not all textures need to be disposed:
         *  SubTextures (created with 'Texture.fromTexture') just reference other textures and
         *  and do not take up resources themselves; this is also true for textures from an
         *  atlas. */
    public function dispose():Void
    {
        // override in subclasses
    }

    /** Creates a texture from any of the supported data types, using the specified options.
         *
         *  @param data     Either an embedded asset class, a Bitmap, BitmapData, or a ByteArray
         *                  with ATF data.
         *  @param options  Specifies options about the texture settings, e.g. the scale factor.
         *                  If left empty, the default options will be used.
         */
    public static function fromData(data:Data, options:TextureOptions=null):Texture
    {
//        if (data is Bitmap)  data = (data as Bitmap).bitmapData;
//        if (options == null) options = sDefaultOptions;
//
//        if (data is Class)
//        {
//        return fromEmbeddedAsset(data as Class,
//        options.mipMapping, options.optimizeForRenderToTexture,
//        options.scale, options.format);
//        }
//        else if (data is BitmapData)
//        {
//        return fromBitmapData(data as BitmapData,
//        options.mipMapping, options.optimizeForRenderToTexture,
//        options.scale, options.format);
//        }
//        else if (data is ByteArray)
//        {
//        return fromAtfData(data as ByteArray,
//        options.scale, options.mipMapping, options.onReady);
//        }
//        else
//        throw new ArgumentError("Unsupported 'data' type: " + getQualifiedClassName(data));
    }




    /** Creates a texture object from a bitmap.
         *  Beware: you must not dispose the bitmap's data if Starling should handle a lost device
         *  context alternatively, you can handle restoration yourself via "texture.root.onRestore".
         *
         *  @param bitmap   the texture will be created with the bitmap data of this object.
         *  @param generateMipMaps  indicates if mipMaps will be created.
         *  @param optimizeForRenderToTexture  indicates if this texture will be used as
         *                  render target
         *  @param scale    the scale factor of the created texture. This affects the reported
         *                  width and height of the texture object.
         *  @param format   the context3D texture format to use. Pass one of the packed or
         *                  compressed formats to save memory (at the price of reduced image
         *                  quality).
         */

    /** Creates a texture object from bitmap data.
         *  Beware: you must not dispose 'data' if Starling should handle a lost device context;
         *  alternatively, you can handle restoration yourself via "texture.root.onRestore".
         *
         *  @param data   the texture will be created with the bitmap data of this object.
         *  @param generateMipMaps  indicates if mipMaps will be created.
         *  @param optimizeForRenderToTexture  indicates if this texture will be used as
         *                  render target
         *  @param scale    the scale factor of the created texture. This affects the reported
         *                  width and height of the texture object.
         *  @param format   the context3D texture format to use. Pass one of the packed or
         *                  compressed formats to save memory (at the price of reduced image
         *                  quality).
         */
    public static function fromBitmapData(data:Data, generateMipMaps:Bool=false,
                                          optimizeForRenderToTexture:Bool=false,
                                          scale:Float=1, format:String="bgra"):Texture
    {
//        var texture:Texture = Texture.empty(data.width / scale, data.height / scale, true,
//        generateMipMaps, optimizeForRenderToTexture, scale,
//        format);
//
//        texture.root.uploadBitmapData(data);
//        texture.root.onRestore = function():Void
//        {
//            texture.root.uploadBitmapData(data);
//        };
//
//        return texture;
    }


    /** Creates a texture with a certain size and color.
         *
         *  @param width   in points; Float of pixels depends on scale parameter
         *  @param height  in points; Float of pixels depends on scale parameter
         *  @param color   the RGB color the texture will be filled up
         *  @param alpha   the alpha value that will be used for every pixel
         *  @param optimizeForRenderToTexture  indicates if this texture will be used as render target
         *  @param scale   if you omit this parameter, 'Starling.contentScaleFactor' will be used.
         *  @param format  the context3D texture format to use. Pass one of the packed or
         *                 compressed formats to save memory.
         */
    public static function fromColor(width:Float, height:Float,
                                     color:UInt=0xffffff, alpha:Float=1.0,
                                     optimizeForRenderToTexture:Bool=false,
                                     scale:Float=-1, format:String="bgra"):Texture
    {
//        var texture:Texture = Texture.empty(width, height, true, false,
//        optimizeForRenderToTexture, scale, format);
//        texture.root.clear(color, alpha);
//        texture.root.onRestore = function():Void
//        {
//            texture.root.clear(color, alpha);
//        };
//
//        return texture;
    }

    /** Creates an empty texture of a certain size.
         *  Beware that the texture can only be used after you either upload some color data
         *  ("texture.root.upload...") or clear the texture ("texture.root.clear()").
         *
         *  @param width   in points; Float of pixels depends on scale parameter
         *  @param height  in points; Float of pixels depends on scale parameter
         *  @param premultipliedAlpha  the PMA format you will use the texture with. If you will
         *                 use the texture for bitmap data, use "true"; for ATF data, use "false".
         *  @param mipMapping  indicates if mipmaps should be used for this texture. When you upload
         *                 bitmap data, this decides if mipmaps will be created; when you upload ATF
         *                 data, this decides if mipmaps inside the ATF file will be displayed.
         *  @param optimizeForRenderToTexture  indicates if this texture will be used as render target
         *  @param scale   if you omit this parameter, 'Starling.contentScaleFactor' will be used.
         *  @param format  the context3D texture format to use. Pass one of the packed or
         *                 compressed formats to save memory (at the price of reduced image quality).
         */
    public static function empty(width:Float, height:Float, premultipliedAlpha:Bool=true,
                                 mipMapping:Bool=false, optimizeForRenderToTexture:Bool=false,
                                 scale:Float=-1, format:String="bgra"):Texture
    {
//        if (scale <= 0) scale = Starling.contentScaleFactor;
//
//        var actualWidth:Int, actualHeight:Int;
//        var nativeTexture:GLTexture;
//        var concreteTexture:ConcreteTexture;
//
//
//        var origWidth:Float  = width  * scale;
//        var origHeight:Float = height * scale;
//        var useRectTexture:Bool = !mipMapping &&
//        Starling.current.profile != "baselineConstrained" &&
//        format.indexOf("compressed") == -1;
//
//        if (useRectTexture)
//        {
//            actualWidth  = Math.ceil(origWidth  - 0.000000001); // avoid floating point errors
//            actualHeight = Math.ceil(origHeight - 0.000000001);
//
//            nativeTexture = context.createRectangleTexture(
//                actualWidth, actualHeight, format, optimizeForRenderToTexture);
//
//            concreteTexture = new ConcreteRectangleTexture(
//            nativeTexture as RectangleTexture, format, actualWidth, actualHeight,
//        premultipliedAlpha, optimizeForRenderToTexture, scale);
//        }
//        else
//        {
//            actualWidth  = MathUtil.getNextPowerOfTwo(origWidth);
//            actualHeight = MathUtil.getNextPowerOfTwo(origHeight);
//
//            nativeTexture = context.createTexture(
//                actualWidth, actualHeight, format, optimizeForRenderToTexture);
//
//            concreteTexture = new ConcretePotTexture(
//            nativeTexture as flash.display3D.textures.Texture, format,
//        actualWidth, actualHeight, mipMapping, premultipliedAlpha,
//            optimizeForRenderToTexture, scale);
//        }
//
//        concreteTexture.onRestore = concreteTexture.clear;
//
//        if (actualWidth - origWidth < 0.001 && actualHeight - origHeight < 0.001)
//            return concreteTexture;
//        else
//            return new SubTexture(concreteTexture, new Rectangle(0, 0, width, height), true);
    }

    /** Creates a texture that contains a region (in pixels) of another texture. The new
         *  texture will reference the base texture; no data is duplicated.
         *
         *  @param texture  The texture you want to create a SubTexture from.
         *  @param region   The region of the parent texture that the SubTexture will show
         *                  (in points).
         *  @param frame    If the texture was trimmed, the frame rectangle can be used to restore
         *                  the trimmed area.
         *  @param rotated  If true, the SubTexture will show the parent region rotated by
         *                  90 degrees (CCW).
         */
    public static function fromTexture(texture:Texture, region:Rectangle=null,
                                       frame:Rectangle=null, rotated:Bool=false):Texture
    {
        return new SubTexture(texture, region, false, frame, rotated);
    }

    /** Sets up a VertexData instance with the correct positions for 4 vertices so that
         *  the texture can be mapped onto it unscaled. If the texture has a <code>frame</code>,
         *  the vertices will be offset accordingly.
         *
         *  @param vertexData  the VertexData instance to which the positions will be written.
         *  @param vertexID    the start position within the VertexData instance.
         *  @param attrName    the attribute name referencing the vertex positions.
         *  @param bounds      useful only for textures with a frame. This will position the
         *                     vertices at the correct position within the given bounds,
         *                     distorted appropriately.
         */
    public function setupVertexPositions(vertexData:VertexData, vertexID:Int=0,
                                         attrName:String="position",
                                         bounds:Rectangle=null):Void
    {
        var frame:Rectangle = this.frame;
        var width:Float    = this.width;
        var height:Float   = this.height;

        if (frame)
            sRectangle.setTo(-frame.x, -frame.y, width, height);
        else
            sRectangle.setTo(0, 0, width, height);

        vertexData.setPoint(vertexID,     attrName, sRectangle.left,  sRectangle.top);
        vertexData.setPoint(vertexID + 1, attrName, sRectangle.right, sRectangle.top);
        vertexData.setPoint(vertexID + 2, attrName, sRectangle.left,  sRectangle.bottom);
        vertexData.setPoint(vertexID + 3, attrName, sRectangle.right, sRectangle.bottom);

        if (bounds)
        {
            var scaleX:Float = bounds.width  / frameWidth;
            var scaleY:Float = bounds.height / frameHeight;

            if (scaleX != 1.0 || scaleY != 1.0)
            {
                sMatrix.identity();
                sMatrix.scale(scaleX, scaleY);
                sMatrix.translate(bounds.x, bounds.y);
                vertexData.transformPoints(attrName, sMatrix, vertexID, 4);
            }
        }
    }

    /** Sets up a VertexData instance with the correct texture coordinates for
         *  4 vertices so that the texture is mapped to the complete quad.
         *
         *  @param vertexData  the vertex data to which the texture coordinates will be written.
         *  @param vertexID    the start position within the VertexData instance.
         *  @param attrName    the attribute name referencing the vertex positions.
         */
    public function setupTextureCoordinates(vertexData:VertexData, vertexID:Int=0,
                                            attrName:String="texCoords"):Void
    {
        setTexCoords(vertexData, vertexID    , attrName, 0.0, 0.0);
        setTexCoords(vertexData, vertexID + 1, attrName, 1.0, 0.0);
        setTexCoords(vertexData, vertexID + 2, attrName, 0.0, 1.0);
        setTexCoords(vertexData, vertexID + 3, attrName, 1.0, 1.0);
    }

    /** Transforms the given texture coordinates from the local coordinate system
         *  into the root texture's coordinate system. */
    public function localToGlobal(u:Float, v:Float, out:Point=null):Point
    {
        if (out == null) out = new Point();
        if (this == root) out.setTo(u, v);
        else MatrixUtil.transformCoords(transformationMatrixToRoot, u, v, out);
        return out;
    }

    /** Transforms the given texture coordinates from the root texture's coordinate system
         *  to the local coordinate system. */
    public function globalToLocal(u:Float, v:Float, out:Point=null):Point
    {
        if (out == null) out = new Point();
        if (this == root) out.setTo(u, v);
        else
        {
            sMatrix.identity();
            sMatrix.copyFrom(transformationMatrixToRoot);
            sMatrix.invert();
            MatrixUtil.transformCoords(sMatrix, u, v, out);
        }
        return out;
    }

    /** Writes the given texture coordinates to a VertexData instance after transforming
         *  them into the root texture's coordinate system. That way, the texture coordinates
         *  can be used directly to sample the texture in the fragment shader. */
    public function setTexCoords(vertexData:VertexData, vertexID:Int, attrName:String,
                                 u:Float, v:Float):Void
    {
        localToGlobal(u, v, sPoint);
        vertexData.setPoint(vertexID, attrName, sPoint.x, sPoint.y);
    }

    /** Reads a pair of texture coordinates from the given VertexData instance and transforms
         *  them into the current texture's coordinate system. (Remember, the VertexData instance
         *  will always contain the coordinates in the root texture's coordinate system!) */
    public function getTexCoords(vertexData:VertexData, vertexID:Int,
                                 attrName:String="texCoords", out:Point=null):Point
    {
        if (out == null) out = new Point();
        vertexData.getPoint(vertexID, attrName, out);
        return globalToLocal(out.x, out.y, out);
    }

    // properties

    /** The texture frame if it has one (see class description), otherwise <code>null</code>.
         *  <p>CAUTION: not a copy, but the actual object! Do not modify!</p> */
    public var frame(get, null): Rectangle;
    private function get_frame():Rectangle { return null; }

    /** The height of the texture in points, taking into account the frame rectangle
         *  (if there is one). */
    public var frameWidth(get, null): Float;
    private function get_frameWidth():Float { return frame ? frame.width : width; }

    /** The width of the texture in points, taking into account the frame rectangle
         *  (if there is one). */
    public var frameHeight(get, null): Float;
    private function get_frameHeight():Float { return frame ? frame.height : height; }

    /** The width of the texture in points. */
    public var width(get, null): Float;
    public function get_width():Float { return 0; }

    /** The height of the texture in points. */
    public var height(get, null): Float;
    public function get_height():Float { return 0; }

    /** The width of the texture in pixels (without scale adjustment). */
    public var nativeWidth(get, null): Float;
    public function get_nativeWidth():Float { return 0; }

    /** The height of the texture in pixels (without scale adjustment). */
    public var nativeHeight(get, null): Float;
    public function get_nativeHeight():Float { return 0; }

    /** The scale factor, which influences width and height properties. */
    public var scale(get, null): Float;
    public function get_scale():Float { return 1.0; }

    /** The opengl texture object the texture is based on. */

    public function get_base():GLTexture { return null; }

    /** The concrete texture the texture is based on. */
    public var root(get, null):ConcreteTexture;
    public function get_root():ConcreteTexture { return null; }

    /** The <code>Context3DTextureFormat</code> of the underlying texture data. */
    public var format(get, null): String;
    public function get_format():String { return "bgra"; }

    /** Indicates if the texture contains mip maps. */
    public var mipMapping(get, null): Bool;
    public function get_mipMapping():Bool { return false; }

    /** Indicates if the alpha values are premultiplied into the RGB values. */
    public var premultipliedAlpha(get, null): Bool;
    public function get_premultipliedAlpha():Bool { return false; }

    /** The matrix that is used to transform the texture coordinates into the coordinate
         *  space of the parent texture, if there is one. @default null
         *
         *  <p>CAUTION: not a copy, but the actual object! Never modify this matrix!</p> */
    public var transformationMatrix(get, null):Matrix;
    public function get_transformationMatrix():Matrix { return null; }

    /** The matrix that is used to transform the texture coordinates into the coordinate
         *  space of the root texture, if this instance is not the root. @default null
         *
         *  <p>CAUTION: not a copy, but the actual object! Never modify this matrix!</p> */
    public var transformationMatrixToRoot(get, null): Matrix;
    public function get_transformationMatrixToRoot():Matrix { return null; }

    /** Returns the maximum size constraint (for both width and height) for textures in the
         *  current Context3D profile. */
    public var maxSize(get, null): Int;
    public static function get_maxSize():Int
    {
        var queryMaxTextureSize: Null<Int> = GL.getParameter(GLDefines.MAX_TEXTURE_SIZE);
        if(queryMaxTextureSize != null)
        {
            return queryMaxTextureSize;
        }
        return 2048;
    }
}
