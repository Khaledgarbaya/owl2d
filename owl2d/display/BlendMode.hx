package owl2d.display;
import gl.GLDefines;
class BlendMode {
    private var _name:String;
    private var _sourceFactor:String;
    private var _destinationFactor:String;

    private static var sBlendModes:Map<String, BlendMode>;

    /** Creates a Owl2d BlendMode instance. Don't call this method directly; instead,
         *  register a Owl2d blend mode using <code>BlendMode.register</code>. */

    public function new(name:String, sourceFactor:String, destinationFactor:String) {
        _name = name;
        _sourceFactor = sourceFactor;
        _destinationFactor = destinationFactor;
    }

    /** Inherits the blend mode from this display object's parent. */
    public static inline var AUTO:String = "auto";

    /** Deactivates blending, i.e. disabling any transparency. */
    public static inline var NONE:String = "none";

    /** The display object appears in front of the background. */
    public static inline var NORMAL:String = "normal";

    /** Adds the values of the colors of the display object to the colors of its background. */
    public static inline var ADD:String = "add";

    /** Multiplies the values of the display object colors with the the background color. */
    public static inline var MULTIPLY:String = "multiply";

    /** Multiplies the complement (inverse) of the display object color with the complement of
          * the background color, resulting in a bleaching effect. */
    public static inline var SCREEN:String = "screen";

    /** Erases the background when drawn on a RenderTexture. */
    public static inline var ERASE:String = "erase";

    /** When used on a RenderTexture, the drawn object will act as a mask for the current
         *  content, i.e. the source alpha overwrites the destination alpha. */
    public static inline var MASK:String = "mask";

    /** Draws under/below existing objects; useful especially on RenderTextures. */
    public static inline var BELOW:String = "below";

    // static access methods

    /** Returns the blend mode with the given name.
         *  Throws an ArgumentError if the mode does not exist. */

    public static function get(modeName:String):BlendMode {
        if (sBlendModes == null) registerDefaults();
        if (sBlendModes.exists(modeName)) return sBlendModes[modeName];
        else throw "Blend mode not found: " + modeName;
    }

    /** Registers a blending mode under a certain name. */

    public static function register(name:String, srcFactor:String, dstFactor:String):BlendMode {
        if (sBlendModes == null) registerDefaults();
        var blendMode:BlendMode = new BlendMode(name, srcFactor, dstFactor);
        sBlendModes[name] = blendMode;
        return blendMode;
    }

    private static function registerDefaults():Void {
        if (sBlendModes) return;

        sBlendModes = new Map<String, BlendMode>();

        register("none", GLDefines.ONE, GLDefines.ZERO);
        register("normal", GLDefines.ONE, GLDefines.ONE_MINUS_SRC_ALPHA);
        register("add", GLDefines.ONE, GLDefines.ONE);
        register("multiply", GLDefines.DST_COLOR, GLDefines.ONE_MINUS_SRC_ALPHA);
        register("screen", GLDefines.ONE, GLDefines.ONE_MINUS_SRC_COLOR);
        register("erase", GLDefines.ZERO, GLDefines.ONE_MINUS_SRC_ALPHA);
        register("mask", GLDefines.ZERO, GLDefines.SRC_ALPHA);
        register("below", GLDefines.ONE_MINUS_DST_ALPHA, GLDefines.DST_ALPHA);
    }

    // instance methods / properties

    /** Sets the appropriate blend factors for source and destination on the current context. */

    public function activate():Void {
        Starling.context.setBlendFactors(_sourceFactor, _destinationFactor);
    }

    /** Returns the name of the blend mode. */

    public function toString():String { return _name; }

    /** The source blend factor of this blend mode. */
    public var sourceFactor(get, null):String;

    public function get_sourceFactor():String { return _sourceFactor; }

    /** The destination blend factor of this blend mode. */
    public var destinationFactor(get, null):String;

    public function get_destinationFactor():String { return _destinationFactor; }

    /** Returns the name of the blend mode. */
    public var name(get, null):String;

    public function get_name():String { return _name; }
}
