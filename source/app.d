import TArGeD.Image;
import std.stdio;

void main() {
	TGAImage i = new TGAImage("sample/UBW8.TGA");
	writeln(i.ImageHeader);
}
