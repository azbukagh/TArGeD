import std.stdio;
import TArGeD;
void main() {
	auto i = Image("sample/CBW8.TGA");
	writeln("Header:");
	writeln("\tIDLength:\t", i.Header.IDLength);
	writeln("\tCMapType:\t", i.Header.CMapType);
	writeln("\tIType:\t", i.Header.IType);
	writeln("\tCMapOffset:\t", i.Header.CMapOffset);
	writeln("\tCMapLength:\t", i.Header.CMapLength);
	writeln("\tCMapDepth:\t", i.Header.CMapDepth);
	writeln("\tXOrigin:\t", i.Header.XOrigin);
	writeln("\tYOrigin:\t", i.Header.YOrigin);
	writefln("\tSize:\t%dx%d", i.Header.Width, i.Header.Height);
	writeln("\tPixelDepth:\t", i.Header.PixelDepth);
	writefln("\tImageDescriptor:\t%b", i.Header.ImageDescriptor);

	writefln("\tID:\t[%(%s, %)]", i.ID);
//	if(i.ColorMap.length != 0) {
//		writeln("ColorMap:");
//		for(size_t k = 0; k < i.ColorMap.length; k++) {
//			writefln("\t#%3d:\tR: %3d\tG: %3d\tB: %3d\tA: %3d",
//				k,
//				i.ColorMap[k].R,
//				i.ColorMap[k].G,
//				i.ColorMap[k].B,
//				i.ColorMap[k].A);
//		}
//	}

	writefln("\tThere are %d pixels", i.Pixels.length);
}
