package hx2d.utils;
class BaseGLSLProgram
{
    public var name: String;
    public function new(name: String)
    {
        this.name = name;
    }

    public function compile(): Void
    {
    }
    public function link(): Void
    {
    }

    public function enableProgram(): Void
    {
    }
    public function disableProgram(): Void
    {
    }
}
