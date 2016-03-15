package owl2d.events;
import owl2d.display.DisplayObject;
class EventDispatcher {
    private var _eventListeners:Map<Dynamic, Dynamic>;

    /** Helper object. */
    private static var sBubbleChains = [];

    /** Creates an EventDispatcher. */

    public function EventDispatcher() { }

    /** Registers an event listener at a certain object. */

    public function addEventListener(type:String, listener:Dynamic):Void {
        if (_eventListeners == null)
            _eventListeners = new Map<Dynamic, Dynamic>();

        var listeners:Array<Dynamic> = _eventListeners[type];
        if (listeners == null)
            _eventListeners[type] = new Array<Dynamic>();
        else if (listeners.indexOf(listener) == -1) // check for duplicates
            listeners[listeners.length] = listener; // avoid 'push'
    }

    /** Removes an event listener from the object. */

    public function removeEventListener(type:String, listener:Dynamic):Void {
        if (_eventListeners) {
            var listeners:Array<Dynamic> = _eventListeners[type];
            var numListeners:Int = listeners ? listeners.length : 0;

            if (numListeners > 0) {
                // we must not modify the original vector, but work on a copy.
                // (see comment in 'invokeEvent')

                var index:Int = listeners.indexOf(listener);

                if (index != -1) {
                    var restListeners:Array<Dynamic> = listeners.slice(0, index);

                    for (i in index + 1...numListeners)
                        restListeners[i - 1] = listeners[i];

                    _eventListeners[type] = restListeners;
                }
            }
        }
    }

    /** Removes all event listeners with a certain type, or all of them if type is null.
         *  Be careful when removing all event listeners: you never know who else was listening. */

    public function removeEventListeners(type:String = null):Void {
        if (type != null && _eventListeners != null)
            _eventListeners.remove(type)
        else
            _eventListeners = null;
    }

    /** Dispatches an event to all objects that have registered listeners for its type.
         *  If an event with enabled 'bubble' property is dispatched to a display object, it will
         *  travel up along the line of parents, until it either hits the root object or someone
         *  stops its propagation manually. */

    public function dispatchEvent(event:Event):Void {
        var bubbles:Bool = event.bubbles;

        if (!bubbles && (_eventListeners == null || !(_eventListeners.exists(event.type))))
            return; // no need to do anything

        // we save the current target and restore it later;
        // this allows users to re-dispatch events without creating a clone.

        var previousTarget:EventDispatcher = event.target;
        event.setTarget(this);

        if (bubbles && Std.is(this, DisplayObject)) bubbleEvent(event);
        else invokeEvent(event);

        if (previousTarget) event.setTarget(previousTarget);
    }

    /** @private
         *  Invokes an event on the current object. This method does not do any bubbling, nor
         *  does it back-up and restore the previous target on the event. The 'dispatchEvent'
         *  method uses this method internally. */

    private function invokeEvent(event:Event):Bool {
        var listeners:Array<Dynamic> = _eventListeners ?
        cast(_eventListeners[event.type], Array<Dynamic>) : null;
        var numListeners:Int = listeners == null ? 0 : listeners.length;

        if (numListeners) {
            event.setCurrentTarget(this);

            // we can enumerate directly over the vector, because:
            // when somebody modifies the list while we're looping, "addEventListener" is not
            // problematic, and "removeEventListener" will create a Owl2d Vector, anyway.

            for (i in 0...numListeners) {
                var listener = listeners[i];
                var numArgs:Int = listener.length;

                if (numArgs == 0) listener();
                else if (numArgs == 1) listener(event);
                else listener(event, event.data);

                if (event.stopsImmediatePropagation)
                    return true;
            }

            return event.stopsPropagation;
        }
        else {
            return false;
        }
    }

    /** @private */

    private function bubbleEvent(event:Event):Void {
        // we determine the bubble chain before starting to invoke the listeners.
        // that way, changes done by the listeners won't affect the bubble chain.

        var chain:Array<EventDispatcher>;
        var element:DisplayObject = cast(this, DisplayObject);
        var length:Int = 1;

        if (sBubbleChains.length > 0) {
            chain = sBubbleChains.pop(); chain[0] = element;
        }
        else {chain = new Array<EventDispatcher>();chain.push(element);}

        while ((element = element.parent) != null)
            chain[length++] = element;

        for (i in 0...length) {
            var stopPropagation:Bool = chain[i].invokeEvent(event);
            if (stopPropagation) break;
        }

        chain.length = 0;
        sBubbleChains[sBubbleChains.length] = chain; // avoid 'push'
    }

    /** Dispatches an event with the given parameters to all objects that have registered
         *  listeners for the given type. The method uses an internal pool of event objects to
         *  avoid allocations. */

    public function dispatchEventWith(type:String, bubbles:Bool = false, data:Dynamic = null):Void {
        if (bubbles || hasEventListener(type)) {
            var event:Event = Event.fromPool(type, bubbles, data);
            dispatchEvent(event);
            Event.toPool(event);
        }
    }

    /** If called with one argument, figures out if there are any listeners registered for
         *  the given event type. If called with two arguments, also determines if a specific
         *  listener is registered. */

    public function hasEventListener(type:String, listener:Dynamic = null):Bool {
        var listeners = _eventListeners ? _eventListeners[type] : null;
        if (listeners == null) return false;
        else {
            if (listener != null) return listeners.indexOf(listener) != -1;
            else return listeners.length != 0;
        }
    }
}