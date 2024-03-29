package owl2d.rendering;
import owl2d.utils.MathUtil;
import owl2d.geom.Matrix;
import owl2d.display.Mesh;
class BatchProcessor {
    private var _batches:Array<MeshBatch>;
    private var _batchPool:BatchPool;
    private var _currentBatch:MeshBatch;
    private var _currentStyleType:Class;
    private var _onBatchComplete:MeshBatch -> Void;
    private var _cacheToken:BatchToken;

    // helper objects
    private static var sMeshSubset:MeshSubset = new MeshSubset();

    /** Creates a new batch processor. */

    public function new() {
        _batches = [];
        _batchPool = new BatchPool();
        _cacheToken = new BatchToken();
    }

    /** Disposes all batches (including those in the reusable pool). */

    public function dispose():Void {
        for (batch in _batches)
            batch.dispose();

        _batches.length = 0;
        _batchPool.purge();
        _currentBatch = null;
    }

    /** Adds a mesh to the current batch, or to a new one if the current one does not support
         *  it. Whenever the batch changes, <code>onBatchComplete</code> is called for the previous
         *  one.
         *
         *  @param mesh       the mesh to add to the current (or new) batch.
         *  @param state      the render state from which to take the current settings for alpha,
         *                    modelview matrix, and blend mode.
         *  @param subset     the subset of the mesh you want to add, or <code>null</code> for
         *                    the complete mesh.
         *  @param ignoreTransformations   when enabled, the mesh's vertices will be added
         *                    without transforming them in any way (no matter the value of the
         *                    state's <code>modelviewMatrix</code>).
         */

    public function addMesh(mesh:Mesh, state:RenderState, subset:MeshSubset = null,
                            ignoreTransformations:Bool = false):Void {
        if (subset == null) {
            subset = sMeshSubset;
            subset.vertexID = subset.indexID = 0;
            subset.numVertices = mesh.numVertices;
            subset.numIndices = mesh.numIndices;
        }
        else {
            if (subset.numVertices < 0) subset.numVertices = mesh.numVertices - subset.vertexID;
            if (subset.numIndices < 0) subset.numIndices = mesh.numIndices - subset.indexID;
        }

        if (subset.numVertices > 0) {
            if (_currentBatch == null || !_currentBatch.canAddMesh(mesh, subset.numVertices)) {
                finishBatch();

                _currentStyleType = mesh.style.type;
                _currentBatch = _batchPool.get(_currentStyleType);
                _currentBatch.blendMode = state ? state.blendMode : mesh.blendMode;
                _cacheToken.setTo(_batches.length);
                _batches[_batches.length] = _currentBatch;
            }

            var matrix:Matrix = state ? state.modelviewMatrix : null;
            var alpha:Float = state ? state.alpha : 1.0;

            _currentBatch.addMesh(mesh, matrix, alpha, subset, ignoreTransformations);
            _cacheToken.vertexID += subset.numVertices;
            _cacheToken.indexID += subset.numIndices;
        }
    }

    /** Finishes the current batch, i.e. call the 'onComplete' callback on the batch and
         *  prepares initialization of a new one. */

    public function finishBatch():Void {
        var meshBatch:MeshBatch = _currentBatch;

        if (meshBatch) {
            _currentBatch = null;
            _currentStyleType = null;

            if (_onBatchComplete != null)
                _onBatchComplete(meshBatch);
        }
    }

    /** Clears all batches and adds them to a pool so they can be reused later. */

    public function clear():Void {
        var numBatches:Int = _batches.length;

        for (i in 0...numBatches)
            _batchPool.put(_batches[i]);

        _batches.length = 0;
        _currentBatch = null;
        _currentStyleType = null;
        _cacheToken.reset();
    }

    /** Returns the batch at a certain index. */

    public function getBatchAt(batchID:Int):MeshBatch {
        return _batches[batchID];
    }

    /** Disposes all batches that are currently unused. */

    public function trim():Void {
        _batchPool.purge();
    }

    public function rewindTo(token:BatchToken):Void {
        if (token.batchID > _cacheToken.batchID)
            throw "Token outside available range";
        var i:Int = _cacheToken.batchID;
        while (i <= token.batchID) {
            _batchPool.put(_batches.pop());
            --i;
        }

        if (_batches.length > token.batchID) {
            var batch:MeshBatch = _batches[token.batchID];
            batch.numIndices = MathUtil.min(batch.numIndices, token.indexID);
            batch.numVertices = MathUtil.min(batch.numVertices, token.vertexID);
        }

        _currentBatch = null;
        _cacheToken.copyFrom(token);
    }

    /** Sets all properties of the given token so that it describes the current position
         *  within this instance. */

    public function fillToken(token:BatchToken):BatchToken {
        token.batchID = _cacheToken.batchID;
        token.vertexID = _cacheToken.vertexID;
        token.indexID = _cacheToken.indexID;
        return token;
    }

    /** The Float of batches currently stored in the BatchProcessor. */
    public var numBatches(get, null):Int;

    public function get_numBatches():Int { return _batches.length; }

    /** This callback is executed whenever a batch is finished and replaced by a new one.
         *  The finished MeshBatch is passed to the callback. Typically, this callback is used
         *  to actually render it. */
    public var onBatchComplete(get, set):MeshBatch -> Void;

    public function get_onBatchComplete():MeshBatch -> Void { return _onBatchComplete; }

    public function set_onBatchComplete(value:MeshBatch -> Void):MeshBatch -> Void { _onBatchComplete = value; }
}

class BatchPool {
    private var _batchLists:Map<String, Array<MeshBatch>>;

    public function BatchPool() {
        _batchLists = new Map<String, Array<MeshBatch>>();
    }

    public function purge():Void {
        for (batchList in _batchLists) {
            for (i in 0...batchList.length)
                batchList[i].dispose();

            batchList.length = 0;
        }
    }

    public function get(styleType:Class):MeshBatch {
        var batchList:Array<MeshBatch> = _batchLists[styleType];
        if (batchList == null) {
            batchList = [];
            _batchLists[styleType] = batchList;
        }

        if (batchList.length > 0) return batchList.pop();
        else {
            var batch:MeshBatch = new MeshBatch();
            batch.batchable = false;
            return batch;
        }
    }

    public function put(meshBatch:MeshBatch):Void {
        var styleType:Class = meshBatch.style.type;
        var batchList:Array<MeshBatch> = _batchLists[styleType];
        if (batchList == null) {
            batchList = new <MeshBatch>[];
            _batchLists[styleType] = batchList;
        }

        meshBatch.clear();
        batchList[batchList.length] = meshBatch;
    }
}
