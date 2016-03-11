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

class DisplayObjectContainer extends DisplayObject
{
    private var mChildren: Array<DisplayObject>;
    public function new()
    {
        super();
        mChildren = [];
    }

    override public dispose(): Void
    {
        for (i in 0...mChildren.length)
        {
            mChildren[i].dispose();
        }
        super.dispose();
    }

    /** Adds a child to the container. It will be at the frontmost position. */
    public function addChild(child:DisplayObject):DisplayObject
    {
        return addChildAt(child, mChildren.length);
    }

    /** Adds a child to the container at a certain index. */
    public function addChildAt(child:DisplayObject, index:int):DisplayObject
    {
        var numChildren:int = mChildren.length;

        if (index >= 0 && index <= numChildren)
        {
            if (child.parent == this)
            {
                setChildIndex(child, index);
            }
            else
            {
                child.removeFromParent();

                if (index == numChildren) mChildren[numChildren] = child;
                else spliceChildren(index, 0, child);

                child.setParent(this);
            }

            return child;
        }
        else
        {
            throw "Invalid child index";
        }
    }
    /** Removes a child from the container. If the object is not a child, nothing happens.
     *  If requested, the child will be disposed right away. */
    public function removeChild(child:DisplayObject, dispose:Bool=false):DisplayObject
    {
        var childIndex:int = getChildIndex(child);
        if (childIndex != -1) removeChildAt(childIndex, dispose);
        return child;
    }
    /** Removes a child at a certain index. The index positions of any display objects above
     *  the child are decreased by 1. If requested, the child will be disposed right away. */
    public function removeChildAt(index:int, dispose:Bool=false):DisplayObject
    {
        if (index >= 0 && index < mChildren.length)
        {
            var child:DisplayObject = mChildren[index];
            child.setParent(null);
            index = mChildren.indexOf(child); // index might have changed by event handler
            if (index >= 0) spliceChildren(index, 1);
            if (dispose) child.dispose();

            return child;
        }
        else
        {
            throw "Invalid child index";
        }
    }
    /** Removes a range of children from the container (endIndex included).
     *  If no arguments are given, all children will be removed. */
    public function removeChildren(beginIndex:int=0, endIndex:int=-1, dispose:Bool=false):Void
    {
        if (endIndex < 0 || endIndex >= numChildren)
        {
            endIndex = numChildren - 1;
        }

        var i:Int = beginIndex;
        while (i<=endIndex)
        {
            removeChildAt(beginIndex, dispose);
            ++i;
        }
    }

    /** Returns a child object at a certain index. If you pass a negative index,
     *  '-1' will return the last child, '-2' the second to last child, etc. */
    public function getChildAt(index:int):DisplayObject
    {
        var numChildren:int = mChildren.length;

        if (index < 0)
        {
            index = numChildren + index;
        }

        if (index >= 0 && index < numChildren)
        {
            return mChildren[index];
        }
        else
        {
            throw "Invalid child index";
        }
    }

    /** Returns a child object with a certain name (non-recursively). */
    public function getChildByName(name:String):DisplayObject
    {
        var numChildren:int = mChildren.length;
        for (i in 0...numChildren)
        {
            if (mChildren[i].name == name)
            {
                return mChildren[i];
            }
        }

        return null;
    }

    /** Returns the index of a child within the container, or "-1" if it is not found. */
    public function getChildIndex(child:DisplayObject):int
    {
        return mChildren.indexOf(child);
    }

    /** Moves a child to a certain index. Children at and after the replaced position move up.*/
    public function setChildIndex(child:DisplayObject, index:int):Void
    {
        var oldIndex:int = getChildIndex(child);
        if (oldIndex == index)
        {
            return;
        }
        if (oldIndex == -1)
        {
            throw "Not a child of this container";
        }
        spliceChildren(oldIndex, 1);
        spliceChildren(index, 0, child);
    }

    /** Swaps the indexes of two children. */
    public function swapChildren(child1:DisplayObject, child2:DisplayObject):Void
    {
        var index1:int = getChildIndex(child1);
        var index2:int = getChildIndex(child2);

        if (index1 == -1 || index2 == -1)
        {
            throw "Not a child of this container";
        }
        swapChildrenAt(index1, index2);
    }

    /** Swaps the indexes of two children. */
    public function swapChildrenAt(index1:int, index2:int):Void
    {
        var child1:DisplayObject = getChildAt(index1);
        var child2:DisplayObject = getChildAt(index2);
        mChildren[index1] = child2;
        mChildren[index2] = child1;
    }

    /** Sorts the children according to a given function (that works just like the sort function
     *  of the Vector class). */
    public function sortChildren(compareFunction:Function):Void
    {
        // sSortBuffer.length = mChildren.length;
        // mergeSort(mChildren, compareFunction, 0, mChildren.length, sSortBuffer);
        // sSortBuffer.length = 0;
    }

    /** Determines if a certain object is a child of the container (recursively). */
    public function contains(child:DisplayObject):Bool
    {
        while (child)
        {
            if (child == this)
            {
                return true;
            }
            else
            {
                child = child.parent;
            }
        }
        return false;
    }
    /** @inheritDoc */
    override public function render():Void
    {
        var alpha:Float = parentAlpha * this.alpha;
        var numChildren:Int = mChildren.length;

        for (i in 0...numChildren)
        {
            var child: DisplayObject = mChildren[i];

            if (child.hasVisibleArea)
            {
                child.render();
            }
        }
    }
}
