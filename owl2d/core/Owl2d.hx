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

package owl2d.core;
import owl2d.display.DisplayObject;
import owl2d.display.Stage;
class Owl2d
{
    private var stage: Stage;
    private var mainScreen: DisplayObject;
    public function new(mainScreen: DisplayObject)
    {
        if(mainScreen != null)
        {
            throw "::Owl2d:: mainScreen can't be null";
        }

        /// make sure oopengl is in the default state
        setDefaultOpenGLState();

        ///setup stage
        setupStage(mainScreen);
    }

    public function start(): Void
    {
        DuellKit.instance().onRender.add(render);
    }

    public function stop(): Void
    {
        DuellKit.instance().onRender.remove(render);
    }
    private function setupStage(mainScreen: DisplayObject): Void
    {
        stage = new Stage();
        stage.width  = DuellKit.instance().screenWidth;
        stage.height = DuellKit.instance().screenHeight;
        stage.addChild(mainScreen);
    }

    private function render(): Void
    {
        stage.render();
    }
    private function setDefaultOpenGLState(): Void
    {
        GL.enable(GLDefines.BLEND);
        GL.blendFunc(GLDefines.SRC_ALPHA, GLDefines.ONE_MINUS_SRC_ALPHA);

        // This is the correct blend function if your textures have premultiplied alpha
        // GL.blendFunc(GLDefines.ONE, GLDefines.ONE_MINUS_SRC_ALPHA);

        GL.depthFunc(GLDefines.LEQUAL);
        GL.depthMask(false);
        GL.disable(GLDefines.DEPTH_TEST);

        GL.disable(GLDefines.STENCIL_TEST);

        GL.stencilFunc(GLDefines.ALWAYS, 0, 0xFF);
        GL.stencilOp(GLDefines.KEEP, GLDefines.KEEP, GLDefines.KEEP);
        GL.stencilMask(0xFF);

        GL.frontFace(GLDefines.CW);

        GL.enable(GLDefines.CULL_FACE);
        GL.cullFace(GLDefines.BACK);

        GL.disable(GLDefines.SCISSOR_TEST);

        GL.clearColor(0.0, 0.0, 0.0, 1.0);
    }


}
