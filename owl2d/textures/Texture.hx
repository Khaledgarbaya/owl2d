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
import gl.GLTexture;
class Texture
{
    inline static private var vertexShader =
        "
            attribute highp   vec4  a_Position;
            attribute lowp    vec4  a_Color;
            attribute highp   vec2  a_TexCoord;
            uniform highp     float u_Tint;
            varying lowp      vec4  v_Color;
            varying highp     vec2  v_TexCoord;
            void main()
            {
                gl_Position = a_Position;
                v_Color = a_Color * u_Tint;
                v_TexCoord = a_TexCoord;
            }
        ";
    inline static private var fragmentShader =
        "
            uniform sampler2D       s_Texture;
            varying lowp      vec4  v_Color;
            varying highp     vec2  v_TexCoord;
            void main()
            {
                gl_FragColor = texture2D(s_Texture, v_TexCoord) * v_Color;
            }
        ";
    private var texture: GLTexture;

    public function new()
    {

    }
    public static function fromBitmapData(data: Data): Texture
    {

    }
    public static function fromFile(filePath: String = ""): Texture
    {

    }

    public function update(): Void
    {

    }

}
