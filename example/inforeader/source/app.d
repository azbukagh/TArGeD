import std.stdio;
import TArGeD;

void main(string[] args) {
	if(args.length != 2) {
		writefln("Usage: %s <file>", args[0]);
		return;
	}

	auto i = new Image(args[1]);
	writeln("Header:");
	writeln("\tColour mapped?:\t", i.isColourMapped);
	writeln("\tImageType:\t", i.ImageType);
	if(i.isColourMapped)
		writeln("\tColourMapDepth:\t", i.ColourMapDepth);
	writeln("\tXOrigin:\t", i.XOrigin);
	writeln("\tYOrigin:\t", i.YOrigin);
	writefln("\tSize:\t%dx%d", i.Width, i.Height);
	writeln("\tPixelDepth:\t", i.PixelDepth);

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

	writeln("Is new TGA?: ", i.isNew);
//	if(i.isNew) {
//		writefln("\tExtenionAreaOffset:\t0x%x", i.ExtensionAreaOffset);
//		writefln("\tDeveloperDirectoryOffset:\t0x%x", i.DeveloperDirectoryOffset);
//		writeln("ExtensionArea:");
//		writeln("\tSize:\t", i.ExtensionArea.Size);
//		writeln("\tAuthorName:\t", i.ExtensionArea.AuthorName);
//		foreach(size_t l; 0..4)
//			writefln("\tAutorComments[%d]:\t%s",
//				l,
//				i.ExtensionArea.AuthorComments[l]);
//		writeln("\tTimestamp:\t",
//			i.ExtensionArea.Timestamp.toSimpleString);
//		writeln("\tJobName:\t", i.ExtensionArea.JobName);
//		writeln("\tJobTime:\t", i.ExtensionArea.JobTime.toString);
//		writeln("\tSoftwareID:\t", i.ExtensionArea.SoftwareID);
//		writeln("\tSoftwareVersion:\t",
//			i.ExtensionArea.SoftwareVersion.toString);
//		writeln("\tKeyColor:\t", i.ExtensionArea.KeyColor);
//		writeln("\tAspectRatio:\t", i.ExtensionArea.AspectRatio.toString);
//		writeln("\tGamma:\t", i.ExtensionArea.Gamma.toString);

//		writefln("\tColorCorrectionOffset:\t0x%x",
//			i.ExtensionArea.ColorCorrectionOffset);
//		writefln("\tPostageStampOffset:\t0x%x",
//			i.ExtensionArea.PostageStampOffset);
//		writefln("\tScanLineOffset:\t0x%x",
//			i.ExtensionArea.ScanLineOffset);
//		writeln("\tAttributesType:\t",
//			i.ExtensionArea.AttributesType);

//		if(i.ExtensionArea.ScanLineOffset != 0) {
//			writeln("ScanLineTable:");
//			foreach(ref f; i.ScanLineTable)
//				writeln("\t", f);
//		}
//	}
}
