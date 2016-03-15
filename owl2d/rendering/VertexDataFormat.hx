package owl2d.rendering;
import gl.GLDefines;
import gl.GLBuffer;
class VertexDataFormat
{
private var _format:String;
private var _vertexSize:Int;
private var _attributes:Array<VertexDataAttribute>;

    // format cache
private static var sFormats:Map<String, Dynamic> = new Map<Dynamic, Dynamic>();

    /** Don't use the constructor, but call <code>VertexDataFormat.fromString</code> instead.
         *  This allows for efficient format caching. */
public function VertexDataFormat()
{
_attributes = [];
}

    /** Creates a Owl2d VertexDataFormat instance from the given String, or returns one from
         *  the cache (if an equivalent String has already been used before).
         *
         *  @param format
         *
         *  Describes the attributes of each vertex, consisting of a comma-separated
         *  list of attribute names and their format, e.g.:
         *
         *  <pre>"position:float2, texCoords:float2, color:float4"</pre>
         *
         *  <p>This set of attributes will be allocated for each vertex, and they will be
         *  stored in exactly the given order.</p>
         *
         *  <ul>
         *    <li>Names are used to access the specific attributes of a vertex. They are
         *        completely arbitrary.</li>
         *    <li>The currently supported formats are <code>float1 - float4</code>.</li>
         *    <li>Both names and format strings are case-sensitive.</li>
         *    <li>Always use <code>float4</code> for color data that you want to access with the
         *        respective methods.</li>
         *    <li>Furthermore, the attribute names of colors should include the string "color"
         *        (or the uppercase variant). If that's the case, the "alpha" channel of the color
         *        will automatically be initialized with "1.0" when the VertexData object is
         *        created or resized.</li>
         *  </ul>
         */
public static function fromString(format:String):VertexDataFormat
{
if(sFormats.exists(format)){
    return sFormats[format];
}

else
{
var instance:VertexDataFormat = new VertexDataFormat();
instance.parseFormat(format);

var normalizedFormat:String = instance._format;

if (sFormats.exists(normalizedFormat))
{
    instance = sFormats[normalizedFormat];
}

sFormats[format] = instance;
sFormats[normalizedFormat] = instance;

return instance;
}
}

    /** Creates a Owl2d VertexDataFormat instance by appending the given format string
         *  to the current instance's format. */
public function extend(format:String):VertexDataFormat
{
return fromString(_format + ", " + format);
}

    // query methods

    /** Returns the size of a certain vertex attribute. */
public function getSize(attrName:String):Int
{
return getAttribute(attrName).size;
}

    /** Returns the offset of an attribute within a vertex. */
public function getOffset(attrName:String):Int
{
return getAttribute(attrName).offset;
}

    /** Returns the format of a certain vertex attribute, identified by its name.
         *  Possible values: <code>float1, float2, float3, float4</code>. */
public function getFormat(attrName:String):String
{
return getAttribute(attrName).format;
}

    /** Returns the name of the attribute at the given position within the vertex format. */
public function getName(attrIndex:Int):String
{
return _attributes[attrIndex].name;
}

    /** Indicates if the format contains an attribute with the given name. */
public function hasAttribute(attrName:String):Bool
{
var numAttributes:Int = _attributes.length;

for (i in 0...numAttributes)
{
    if (_attributes[i].name == attrName) return true;
}

return false;
}

    // context methods

    /** Specifies which vertex data attribute corresponds to a single vertex shader
         *  program input. This wraps the <code>Context3D</code>-method with the same name,
         *  automatically replacing <code>attrName</code> with the corresponding values for
         *  <code>bufferOffset</code> and <code>format</code>. */
public function setVertexBufferAt(index:Int, buffer:GLBuffer, attrName:String):Void
{
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glVertexAttribPointer(index, attribute.offset, attribute.format, GL_FALSE, 0, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    //Starling.context.setVertexBufferAt(index, buffer, attribute.offset, attribute.format);
}

    // parsing

private function parseFormat(format:String):Void
{
if (format != null && format != "")
{
_attributes.length = 0;
_format = "";

var parts:Array = format.split(",");
var numParts:Int = parts.length;
var offset:Int = 0;

for (var i:Int=0; i<numParts; ++i)
{
var attrDesc:String = parts[i];
var attrParts:Array = attrDesc.split(":");

if (attrParts.length != 2)
throw new ArgumentError("Missing colon: " + attrDesc);

var attrName:String = StringUtil.trim(attrParts[0]);
var attrFormat:String = StringUtil.trim(attrParts[1]);

if (attrName.length == 0 || attrFormat.length == 0)
throw new ArgumentError(("Invalid format string: " + attrDesc));

var attribute:VertexDataAttribute =
new VertexDataAttribute(attrName, attrFormat, offset);

offset += attribute.size;

_format += (i == 0 ? "" : ", ") + attribute.name + ":" + attribute.format;
_attributes[_attributes.length] = attribute; // avoid 'push'
}

_vertexSize = offset;
}
else
{
_format = "";
}
}

    /** Returns the normalized format string. */
public function toString():String
{
return _format;
}

    // internal methods

    /** @private */
internal function getAttribute(attrName:String):VertexDataAttribute
{
var i:Int, attribute:VertexDataAttribute;
var numAttributes:Int = _attributes.length;

for (i=0; i<numAttributes; ++i)
{
attribute = _attributes[i];
if (attribute.name == attrName) return attribute;
}

return null;
}

    /** @private */
internal function get attributes():Vector.<VertexDataAttribute>
{
return _attributes;
}

    // properties

    /** Returns the normalized format string. */
public function get formatString():String
{
return _format;
}

    /** The size (in 32 bit units) of each vertex. */
public function get vertexSize():Int
{
return _vertexSize;
}

    /** The Float of attributes per vertex. */
public function get numAttributes():Int
{
return _attributes.length;
}
}
