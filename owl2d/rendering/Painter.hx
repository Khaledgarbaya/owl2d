package owl2d.rendering;
import gl.GLContext;
import owl2d.utils.MatrixUtil;
import owl2d.textures.Texture;
import owl2d.geom.Matrix3D;
import owl2d.display.Mesh;
import owl2d.utils.MathUtil;
import owl2d.display.Quad;
import owl2d.display.DisplayObject;
import owl2d.display.BlendMode;
import owl2d.geom.Vector3D;
import owl2d.geom.Matrix;
import gl.GLTexture;
import owl2d.geom.Rectangle;
class Painter {
    private var _context:GLContext;
    private var _shareContext:Bool;
    private var _programs:Map<Dynamic, Dynamic>;
    private var _data:Map<Dynamic, Dynamic>;
    private var _drawCount:Int;
    private var _frameID:UInt;
    private var _pixelSize:Float;
    private var _enableErrorChecking:Bool;
    private var _stencilReferenceValues:Map<Dynamic, Dynamic>;
    private var _clipRectStack:Array<Rectangle>;
    private var _batchProcessor:BatchProcessor;
    private var _batchCache:BatchProcessor;

    private var _actualRenderTarget:GLTexture;
    private var _actualCulling:String;
    private var _actualBlendMode:String;

    private var _backBufferWidth:Float;
    private var _backBufferHeight:Float;
    private var _backBufferScaleFactor:Float;

    private var _state:RenderState;
    private var _stateStack:Arra<RenderState>;
    private var _stateStackPos:Int;

    // helper objects
    private static var sMatrix:Matrix = new Matrix();
    private static var sPoint3D:Vector3D = new Vector3D();
    private static var sClipRect:Rectangle = new Rectangle();
    private static var sBufferRect:Rectangle = new Rectangle();
    private static var sScissorRect:Rectangle = new Rectangle();
    private static var sMeshSubset:MeshSubset = new MeshSubset();

    // construction

    /** Creates a new Painter object. Normally, it's not necessary to create any custom
         *  painters; instead, use the global painter found on the Starling instance. */
    public function new()
    {
        _backBufferWidth  = _context ? _context.contextWidth  : 0;
        _backBufferHeight = _context ? _context.contextHeight : 0;
        _backBufferScaleFactor = _pixelSize = 1.0;
        _stencilReferenceValues = new Map<Dynamic, Dynamic>(true);
        _clipRectStack = [];
         _programs = new Map<Dynamic, Program>();
        _data = new Map<Dynamic, Dynamic>();

        _batchProcessor = new BatchProcessor();
        _batchProcessor.onBatchComplete = drawBatch;

        _batchCache = new BatchProcessor();
        _batchCache.onBatchComplete = drawBatch;

        _state = new RenderState();
        _state.onDrawRequired = finishMeshBatch;
         _stateStack = [];
        _stateStackPos = -1;
    }

    /** Disposes all quad batches, programs, and - if it is not being shared -
         *  the render context. */
    public function dispose():Void
    {
        _batchProcessor.dispose();
        _batchCache.dispose();

        if (!_shareContext)
            _context.dispose(false);

        for (program in _programs)
        program.dispose();
    }

    // context handling

    /** Requests a context3D object from the stage3D object.
         *  This is called by Starling internally during the initialization process.
         *  You normally don't need to call this method yourself. (For a detailed description
         *  of the parameters, look at the documentation of the method with the same name in the
         *  "RenderUtil" class.)
         *
         *  @see starling.utils.RenderUtil
         */
    public function requestContext3D(renderMode:String, profile:Dynamic):Void
    {
//        RenderUtil.requestContext3D(_stage3D, renderMode, profile);
    }

    private function onContextCreated():Void
    {
//        _context = _stage3D.context3D;
//        _context.enableErrorChecking = _enableErrorChecking;
//        _actualBlendMode = null;
//        _actualCulling = null;
    }

    /** Sets the viewport dimensions and other attributes of the rendering buffer.
         *  Starling will call this method internally, so most apps won't need to mess with this.
         *
         * @param viewPort                the position and size of the area that should be rendered
         *                                into, in pixels.
         * @param contentScaleFactor      only relevant for Desktop (!) HiDPI screens. If you want
         *                                to support high resolutions, pass the 'contentScaleFactor'
         *                                of the Flash stage; otherwise, '1.0'.
         * @param antiAlias               from 0 (none) to 16 (very high quality).
         * @param enableDepthAndStencil   indicates whether the depth and stencil buffers should
         *                                be enabled. Note that on AIR, you also have to enable
         *                                this setting in the app-xml (application descriptor);
         *                                otherwise, this setting will be silently ignored.
         */
    public function configureBackBuffer(viewPort:Rectangle, contentScaleFactor:Float,
                                        antiAlias:Int, enableDepthAndStencil:Bool):Void
    {
        enableDepthAndStencil &= SystemUtil.supportsDepthAndStencil;

        // Changing the stage3D position might move the back buffer to invalid bounds
        // temporarily. To avoid problems, we set it to the smallest possible size first.

        if (_context.profile == "baselineConstrained")
            _context.configureBackBuffer(32, 32, antiAlias, enableDepthAndStencil);

        _stage3D.x = viewPort.x;
        _stage3D.y = viewPort.y;

        _context.configureBackBuffer(viewPort.width, viewPort.height,
        antiAlias, enableDepthAndStencil, contentScaleFactor != 1.0);

        _backBufferWidth  = viewPort.width;
        _backBufferHeight = viewPort.height;
        _backBufferScaleFactor = contentScaleFactor;
    }

    // program management

    /** Registers a program under a certain name.
         *  If the name was already used, the previous program is overwritten. */
    public function registerProgram(name:String, program:Program):Void
    {
        deleteProgram(name);
        _programs[name] = program;
    }

    /** Deletes the program of a certain name. */
    public function deleteProgram(name:String):Void
    {
        var program:Program = getProgram(name);
        if (program)
        {
            program.dispose();
            delete _programs[name];
        }
    }

    /** Returns the program registered under a certain name, or null if no program with
         *  this name has been registered. */
    public function getProgram(name:String):Program
    {
        if (_programs.exists(name)) return _programs[name];
    else return null;
    }

    /** Indicates if a program is registered under a certain name. */
    public function hasProgram(name:String):Bool
    {
        return _programs.exists(name);
    }

    // state stack

    /** Pushes the current render state to a stack from which it can be restored later.
         *
         *  <p>If you pass a BatchToken, it will be updated to point to the current location within
         *  the render cache. That way, you can later reference this location to render a subset of
         *  the cache.</p>
         */
    public function pushState(token:BatchToken=null):Void
    {
        _stateStackPos++;

        if (_stateStack.length < _stateStackPos + 1) _stateStack[_stateStackPos] = new RenderState();
        if (token) _batchProcessor.fillToken(token);

        _stateStack[_stateStackPos].copyFrom(_state);
    }

    /** Modifies the current state with a transformation matrix, alpha factor, and blend mode.
         *
         *  @param transformationMatrix Used to transform the current <code>modelviewMatrix</code>.
         *  @param alphaFactor          Multiplied with the current alpha value.
         *  @param blendMode            Replaces the current blend mode; except for "auto", which
         *                              means the current value remains unchanged.
         */
    public function setStateTo(transformationMatrix:Matrix, alphaFactor:Float=1.0,
                               blendMode:String="auto"):Void
    {
        if (transformationMatrix) _state.transformModelviewMatrix(transformationMatrix);
        if (alphaFactor != 1.0) _state.alpha *= alphaFactor;
        if (blendMode != BlendMode.AUTO) _state.blendMode = blendMode;
    }

    /** Restores the render state that was last pushed to the stack. If this changes
         *  blend mode, clipping rectangle, render target or culling, the current batch
         *  will be drawn right away.
         *
         *  <p>If you pass a BatchToken, it will be updated to point to the current location within
         *  the render cache. That way, you can later reference this location to render a subset of
         *  the cache.</p>
         */
    public function popState(token:BatchToken=null):Void
    {
        if (_stateStackPos < 0)
            throw "Cannot pop empty state stack";

        _state.copyFrom(_stateStack[_stateStackPos]); // -> might cause 'finishMeshBatch'
        _stateStackPos--;

        if (token) _batchProcessor.fillToken(token);
    }

    // masks

    /** Draws a display object into the stencil buffer, incrementing the buffer on each
         *  used pixel. The stencil reference value is incremented as well; thus, any subsequent
         *  stencil tests outside of this area will fail.
         *
         *  <p>If 'mask' is part of the display list, it will be drawn at its conventional stage
         *  coordinates. Otherwise, it will be drawn with the current modelview matrix.</p>
         *
         *  <p>As an optimization, this method might update the clipping rectangle of the render
         *  state instead of utilizing the stencil buffer. This is possible when the mask object
         *  is of type <code>starling.display.Quad</code> and is aligned parallel to the stage
         *  axes.</p>
         */
    public function drawMask(mask:DisplayObject):Void
    {
        if (_context == null) return;

        finishMeshBatch();

        if (isRectangularMask(mask, sMatrix))
        {
            mask.getBounds(mask, sClipRect);
            RectangleUtil.getBounds(sClipRect, sMatrix, sClipRect);
            pushClipRect(sClipRect);
        }
        else
        {
//            _context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
//            Context3DCompareMode.EQUAL, Context3DStencilAction.INCREMENT_SATURATE);
//
//            renderMask(mask);
//            stencilReferenceValue++;
//
//            _context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
//            Context3DCompareMode.EQUAL, Context3DStencilAction.KEEP);
        }
    }

    /** Draws a display object into the stencil buffer, decrementing the
         *  buffer on each used pixel. This effectively erases the object from the stencil buffer,
         *  restoring the previous state. The stencil reference value will be decremented.
         *
         *  <p>Note: if the mask object meets the requirements of using the clipping rectangle,
         *  it will be assumed that this erase operation undoes the clipping rectangle change
         *  caused by the corresponding <code>drawMask()</code> call.</p>
         */
    public function eraseMask(mask:DisplayObject):Void
    {
        if (_context == null) return;

        finishMeshBatch();

        if (isRectangularMask(mask, sMatrix))
        {
            popClipRect();
        }
        else
        {
//            _context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
//            Context3DCompareMode.EQUAL, Context3DStencilAction.DECREMENT_SATURATE);
//
//            renderMask(mask);
//            stencilReferenceValue--;
//
//            _context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
//            Context3DCompareMode.EQUAL, Context3DStencilAction.KEEP);
        }
    }

    private function renderMask(mask:DisplayObject):Void
    {
        pushState();
        _state.alpha = 0.0;

        if (mask.stage)
            mask.getTransformationMatrix(null, _state.modelviewMatrix);
        else
            _state.transformModelviewMatrix(mask.transformationMatrix);

        mask.render(this);
        finishMeshBatch();

        popState();
    }

    private function pushClipRect(clipRect:Rectangle):Void
    {
        var stack:Arra<Rectangle> = _clipRectStack;
        var stackLength:UInt = stack.length;
        var intersection:Rectangle = Pool.getRectangle();

        if (stackLength)
            RectangleUtil.intersect(stack[stackLength - 1], clipRect, intersection);
        else
            intersection.copyFrom(clipRect);

        stack[stackLength] = intersection;
        _state.clipRect = intersection;
    }

    private function popClipRect():Void
    {
        var stack:Arra<Rectangle> = _clipRectStack;
        var stackLength:UInt = stack.length;

        if (stackLength == 0)
            throw "Trying to pop from empty clip rectangle stack";

        stackLength--;
        Pool.putRectangle(stack.pop());
        _state.clipRect = stackLength ? stack[stackLength - 1] : null;
    }

    /** Figures out if the mask can be represented by a scissor rectangle; this is possible
         *  if it's just a simple quad that is parallel to the stage axes. The 'out' parameter
         *  will be filled with the transformation matrix required to move the mask into stage
         *  coordinates. */
    private function isRectangularMask(mask:DisplayObject, out:Matrix):Bool
    {
        var quad:Quad = mask as Quad;
        if (quad && !quad.is3D && quad.style.type == MeshStyle)
        {
            if (mask.stage) mask.getTransformationMatrix(null, out);
            else
            {
                out.copyFrom(mask.transformationMatrix);
                out.concat(_state.modelviewMatrix);
            }

            return (MathUtil.isEquivalent(out.a, 0) && MathUtil.isEquivalent(out.d, 0)) ||
            (MathUtil.isEquivalent(out.b, 0) && MathUtil.isEquivalent(out.c, 0));
        }
        return false;
    }

    // mesh rendering

    /** Adds a mesh to the current batch of unrendered meshes. If the current batch is not
         *  compatible with the mesh, all previous meshes are rendered at once and the batch
         *  is cleared.
         *
         *  @param mesh    The mesh to batch.
         *  @param subset  The range of vertices to be batched. If <code>null</code>, the complete
         *                 mesh will be used.
         */
    public function batchMesh(mesh:Mesh, subset:MeshSubset=null):Void
    {
        _batchProcessor.addMesh(mesh, _state, subset);
    }

    /** Finishes the current mesh batch and prepares the next one. */
    public function finishMeshBatch():Void
    {
        _batchProcessor.finishBatch();
    }

    /** Completes all unfinished batches, cleanup procedures. */
    public function finishFrame():Void
    {
        if (_frameID % 99 == 0) // odd Float -> alternating processors
            _batchProcessor.trim();

        _batchProcessor.finishBatch();
        swapBatchProcessors();
        _batchProcessor.clear();
    }

    private function swapBatchProcessors():Void
    {
        var tmp:BatchProcessor = _batchProcessor;
        _batchProcessor = _batchCache;
        _batchCache = tmp;
    }

    /** Resets the current state, state stack, batch processor, stencil reference value,
         *  clipping rectangle, and draw count. Furthermore, depth testing is disabled. */
    public function nextFrame():Void
    {
        stencilReferenceValue = 0;
        _clipRectStack.length = 0;
        _drawCount = 0;
        _stateStackPos = -1;
        _batchProcessor.clear();
//        _context.setDepthTest(false, Context3DCompareMode.ALWAYS);
        _state.reset();
    }

    /** Draws all meshes from the render cache between <code>startToken</code> and
         *  (but not including) <code>endToken</code>. The render cache contains all meshes
         *  rendered in the previous frame. */
    public function drawFromCache(startToken:BatchToken, endToken:BatchToken):Void
    {
        var meshBatch:MeshBatch;
        var subset:MeshSubset = sMeshSubset;

        if (!startToken.equals(endToken))
        {
            pushState();

            for (i in startToken.batchID...endToken.batchID)
            {
            meshBatch = _batchCache.getBatchAt(i);
            subset.setTo(); // resets subset

            if (i == startToken.batchID)
            {
            subset.vertexID = startToken.vertexID;
            subset.indexID  = startToken.indexID;
            subset.numVertices = meshBatch.numVertices - subset.vertexID;
            subset.numIndices  = meshBatch.numIndices  - subset.indexID;
            }

            if (i == endToken.batchID)
            {
            subset.numVertices = endToken.vertexID - subset.vertexID;
            subset.numIndices  = endToken.indexID  - subset.indexID;
            }

            if (subset.numVertices > 0)
            {
            _state.alpha = 1.0;
            _state.blendMode = meshBatch.blendMode;
            _batchProcessor.addMesh(meshBatch, _state, subset, true);
            }
            }

            popState();
        }
    }

    /** Removes all parts of the render cache past the given token. Beware that some display
         *  objects might still reference those parts of the cache! Only call it if you know
         *  exactly what you're doing. */
    public function rewindCacheTo(token:BatchToken):Void
    {
        _batchProcessor.rewindTo(token);
    }

    private function drawBatch(meshBatch:MeshBatch):Void
    {
        pushState();

        state.blendMode = meshBatch.blendMode;
        state.modelviewMatrix.identity();
        state.alpha = 1.0;

        meshBatch.render(this);

        popState();
    }

    // helper methods

    /** Applies all relevant state settings to at the render context. This includes
         *  blend mode, render target and clipping rectangle. Always call this method before
         *  <code>context.drawTriangles()</code>.
         */
    public function prepareToDraw():Void
    {
        applyBlendMode();
        applyRenderTarget();
        applyClipRect();
        applyCulling();
    }

    /** Clears the render context with a certain color and alpha value. Since this also
         *  clears the stencil buffer, the stencil reference value is also reset to '0'. */
    public function clear(rgb:UInt=0, alpha:Float=0.0):Void
    {
        applyRenderTarget();
        stencilReferenceValue = 0;
        RenderUtil.clear(rgb, alpha);
    }

    /** Resets the render target to the back buffer and displays its contents. */
    public function present():Void
    {
        _state.renderTarget = null;
        _actualRenderTarget = null;
        _context.present();
    }

    private function applyBlendMode():Void
    {
        var blendMode:String = _state.blendMode;

        if (blendMode != _actualBlendMode)
        {
            BlendMode.get(_state.blendMode).activate();
            _actualBlendMode = blendMode;
        }
    }

    private function applyCulling():Void
    {
        var culling:String = _state.culling;

        if (culling != _actualCulling)
        {
            _context.setCulling(culling);
            _actualCulling = culling;
        }
    }

    private function applyRenderTarget():Void
    {
        var target:GLTexture = _state.renderTargetBase;

        if (target != _actualRenderTarget)
        {
            if (target)
            {
                var antiAlias:Int  = _state.renderTargetAntiAlias;
                var depthAndStencil:Bool = _state.renderTargetSupportsDepthAndStencil;
                _context.setRenderToTexture(target, depthAndStencil, antiAlias);
            }
            else
                _context.setRenderToBackBuffer();

            _context.setStencilReferenceValue(stencilReferenceValue);
            _actualRenderTarget = target;
        }
    }

    private function applyClipRect():Void
    {
        var clipRect:Rectangle = _state.clipRect;

        if (clipRect)
        {
            var width:Int, height:Int;
            var projMatrix:Matrix3D = _state.projectionMatrix3D;
            var renderTarget:Texture = _state.renderTarget;

            if (renderTarget)
            {
                width  = renderTarget.root.nativeWidth;
                height = renderTarget.root.nativeHeight;
            }
            else
            {
                width  = _backBufferWidth;
                height = _backBufferHeight;
            }

            // convert to pixel coordinates (matrix transformation ends up in range [-1, 1])
            MatrixUtil.transformCoords3D(projMatrix, clipRect.x, clipRect.y, 0.0, sPoint3D);
            sPoint3D.project(); // eliminate w-coordinate
            sClipRect.x = (sPoint3D.x * 0.5 + 0.5) * width;
            sClipRect.y = (0.5 - sPoint3D.y * 0.5) * height;

            MatrixUtil.transformCoords3D(projMatrix, clipRect.right, clipRect.bottom, 0.0, sPoint3D);
            sPoint3D.project(); // eliminate w-coordinate
            sClipRect.right  = (sPoint3D.x * 0.5 + 0.5) * width;
            sClipRect.bottom = (0.5 - sPoint3D.y * 0.5) * height;

            sBufferRect.setTo(0, 0, width, height);
            RectangleUtil.intersect(sClipRect, sBufferRect, sScissorRect);

            // an empty rectangle is not allowed, so we set it to the smallest possible size
            if (sScissorRect.width < 1 || sScissorRect.height < 1)
                sScissorRect.setTo(0, 0, 1, 1);

            _context.setScissorRectangle(sScissorRect);
        }
        else
        {
            _context.setScissorRectangle(null);
        }
    }

    // properties

    /** Indicates the Float of stage3D draw calls. */
    public var drawCount(get, set): Int;
    public function get_drawCount():Int { return _drawCount; }
    public function set_drawCount(value:Int):Int { _drawCount = value; return value;}

    /** The current stencil reference value of the active render target. This value
         *  is typically incremented when drawing a mask and decrementing when erasing it.
         *  The painter keeps track of one stencil reference value per render target.
         *  Only change this value if you know what you're doing!
         */
    public var stencilReferenceValue(get, set): UInt;
    public function get_stencilReferenceValue():UInt
    {
        var key:Dynamic = _state.renderTarget ? _state.renderTargetBase : this;
        if (_stencilReferenceValues.exists(key)) return _stencilReferenceValues[key];
    else return 0;
    }

    public function set_stencilReferenceValue(value:UInt):Void
    {
        var key:Dynamic = _state.renderTarget ? _state.renderTargetBase : this;
        _stencilReferenceValues[key] = value;

//        if (contextValid)
//            _context.setStencilReferenceValue(value);
        return value;
    }

    /** The current render state, containing some of the context settings, projection- and
         *  modelview-matrix, etc. Always returns the same instance, even after calls to "pushState"
         *  and "popState".
         *
         *  <p>When you change the current RenderState, and this change is not compatible with
         *  the current render batch, the batch will be concluded right away. Thus, watch out
         *  for changes of blend mode, clipping rectangle, render target or culling.</p>
         */
    public var state(get, null):RenderState;
    public function get_state():RenderState { return _state; }

    /** The GLContext instance this painter renders into. */
    public function get_context():GLContext { return _context; }

    /** The Float of frames that have been rendered with the current Starling instance. */
    public var frameID(get, set):UInt;
    public function get_frameID():UInt { return _frameID; }
    public function set_frameID(value:UInt):UInt { _frameID = value; return value;}

    /** The size (in points) that represents one pixel in the back buffer. */
    public var pixelSize(get, set): Float;
    public function get_pixelSize():Float { return _pixelSize; }
    public function set_pixelSize(value:Float):Void { _pixelSize = value; return value;}

    /** Indicates if another Starling instance (or another Stage3D framework altogether)
         *  uses the same render context. @default false */
    public var shareContext(get, set): Bool;
    public function get_shareContext():Bool { return _shareContext; }
    public function set_shareContext(value:Bool):Bool { _shareContext = value; return value;}

    /** Indicates if Stage3D render methods will report errors. Activate only when needed,
         *  as this has a negative impact on performance. @default false */
    public var enableErrorChecking(get, set): Bool;
    public function get_enableErrorChecking():Bool { return _enableErrorChecking; }
    public function set_enableErrorChecking(value:Bool):Void
    {
        _enableErrorChecking = value;
        if (_context) _context.enableErrorChecking = value;
        return value;
    }

    /** Returns the current width of the back buffer. In most cases, this value is in pixels;
         *  however, if the app is running on an HiDPI display with an activated
         *  'supportHighResolutions' setting, you have to multiply with 'backBufferPixelsPerPoint'
         *  for the actual pixel count. Alternatively, use the Context3D-property with the
         *  same name: it will return the exact pixel values. */
    public var backBufferWidth(get, null):Int;
    public function get_backBufferWidth():Int { return _backBufferWidth; }

    /** Returns the current height of the back buffer. In most cases, this value is in pixels;
         *  however, if the app is running on an HiDPI display with an activated
         *  'supportHighResolutions' setting, you have to multiply with 'backBufferPixelsPerPoint'
         *  for the actual pixel count. Alternatively, use the Context3D-property with the
         *  same name: it will return the exact pixel values. */
    public var backBufferHeight(get, null):Int;
    public function get_backBufferHeight():Int { return _backBufferHeight; }

    /** The Float of pixels per point returned by the 'backBufferWidth/Height' properties.
         *  Except for desktop HiDPI displays with an activated 'supportHighResolutions' setting,
         *  this will always return '1'. */
    public var backBufferScaleFactor(get, null): Float;
    public function get_backBufferScaleFactor():Float { return _backBufferScaleFactor; }

    /** Indicates if the Context3D object is currently valid (i.e. it hasn't been lost or
         *  disposed). */
    public var contextValid(get, null);
    public function get_contextValid():Bool
    {
//        if (_context)
//        {
//            const driverInfo:String = _context.driverInfo;
//        return driverInfo != null && driverInfo != "" && driverInfo != "Disposed";
//        }
//        else return false;
        return true;
    }


    /** A Map<Dynamic, Dynamic> that can be used to save custom data related to the render context.
         *  If you need to share data that is bound to the render context (e.g. textures),
         *  use this Map<Dynamic, Dynamic> instead of creating a static class variable.
         *  That way, the data will be available for all Starling instances that use this
         *  painter / stage3D / context. */
    public var sharedData(get, null):Map<Dynamic, Dynamic>;
    public function get_sharedData():Map<Dynamic, Dynamic> { return _data; }
}
