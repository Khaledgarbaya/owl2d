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
package hx2d.rendering;
class Program
{
    private var _glProgram: GLProgram;
    private var _vertexShader: GLShader;
    private var _fragmentShader: GLShader;

    public function new(vertexShader: GLShader, fragmentShader: GLShader)
    {
        _vertexShader = vertexShader;
        _fragmentShader = fragmentShader;
    }
    public static function fromSource(vertexShaderSource: String, fragmentShaderSource: String): Program
    {
        return new Program(compileShader(GLDefines.VERTEX_SHADER, vertexShaderSource)
                        , compileShader(GLDefines.FRAGMENT_SHADER, fragmentShaderSource));
    }

    public function dispose(): Void
    {
        disposeProgram();
    }

    public function activate(): Void
    {
        if(!linkShader())
        {
            trace("Failed to link program");
            disposeProgram();
            return;
        }
    }
    private function linkShader(): Bool
    {
        GL.linkProgram(_glProgram);

        #if debug
        var log = GL.getProgramInfoLog(_glProgram);
        if(log.length > 0)
        {
            trace("Shader program log:");
            trace(log);
        }
        #end

        if(GL.getProgramParameter(_glProgram, GLDefines.LINK_STATUS) == 0)
            return false;
        return true;
    }
    private function disposeProgram(): Void
    {
        if(_vertexShader != GL.nullShader)
        {
            GL.deleteShader(_vertexShader);
        }
        if(_fragmentShader != GL.nullShader)
        {
            GL.deleteShader(_fragmentShader);
        }
        if(_glProgram != GL.nullProgram)
        {
            GL.deleteProgram(_glProgram);
        }
    }
    private function compileShader(type: Int, code: String): GLShader
    {
        var s = GL.createShader(type);
        GL.shaderSource(s, code);
        GL.compileShader(s);

        #if debug
        var log = GL.getShaderInfoLog(s);
        if(log.length > 0)
        {
            trace("Shader log:");
            trace(log);
        }
        #end

        if(GL.getShaderParameter(s, GLDefines.COMPILE_STATUS) != cast 1 )
        {
            GL.deleteShader(s);
            return GL.nullShader;
        }
        return s;
    }

}
