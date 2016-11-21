import std.stdio;
import TArGeD;

void main(string[] args) {
	if(args.length != 2) {
		writefln("Usage: %s <file>", args[0]);
		return;
	}

	auto i = new TGAImage(args[1]);
	writeln("Header:");
	//writeln("\tColour mapped?:\t", i.isColourMapped);
	writeln("\tImageType:\t", i.ImageType);
	writeln("\tXOrigin:\t", i.XOrigin);
	writeln("\tYOrigin:\t", i.YOrigin);
	writefln("\tSize:\t%dx%d", i.Width, i.Height);
	writeln("\tPixelDepth:\t", i.PixelDepth);

//	writeln(i.Pixels);

	writefln("\tID:\t[%(%s, %)]", i.ID!(ubyte[]));
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

	writeln("\tIs new TGA?: ", i.isNew);
	if(i.isNew) {
		writeln("ExtensionArea:");
		writeln("\tAuthorName:\t", i.AuthorName);
		foreach(size_t l; 0..4)
			writefln("\tAutorComments[%d]:\t%s",
				l,
				i.AuthorComments[l]);
		writeln("\tTimestamp:\t",
			i.Timestamp.toSimpleString);
		writeln("\tJobName:\t", i.JobName);
		writeln("\tJobTime:\t", i.JobTime.toString);
		writeln("\tSoftwareID:\t", i.SoftwareID);
		writeln("\tSoftwareVersion:\t",
			i.SoftwareVersion.toString);
		writeln("\tAspectRatio:\t",
			i.AspectRatio.isPresented == false
				? "false"
				: i.AspectRatio.toString);
		writeln("\tGamma:\t",
			i.Gamma.isPresented == false
				? "false"
				: i.Gamma.toString);
		if(!i.Gamma.isCorrect)
			writeln("\tGamma is not correct");
	}
}
