package owl2d.utils;
class Align {
    /** @private */
    private function Align() { }

    /** Horizontal left alignment. */
    public static inline var LEFT:String = "left";

    /** Horizontal right alignment. */
    public static inline var RIGHT:String = "right";

    /** Vertical top alignment. */
    public static inline var TOP:String = "top";

    /** Vertical bottom alignment. */
    public static inline var BOTTOM:String = "bottom";

    /** Centered alignment. */
    public static inline var CENTER:String = "center";

    /** Indicates whether the given alignment string is valid. */

    public static function isValid(align:String):Bool {
        return align == LEFT || align == RIGHT || align == CENTER ||
        align == TOP || align == BOTTOM;
    }

    /** Indicates if the given string is a valid horizontal alignment. */

    public static function isValidHorizontal(align:String):Bool {
        return align == LEFT || align == CENTER || align == RIGHT;
    }

    /** Indicates if the given string is a valid vertical alignment. */

    public static function isValidVertical(align:String):Bool {
        return align == TOP || align == CENTER || align == BOTTOM;
    }
}
