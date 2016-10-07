import std.stdio;
import TArGeD;

void main(string[] args) {
	if(args.length != 2) {
		writefln("Usage: %s <file>");
		return;
	}

	auto i = Image(args[1]);
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
	writeln("New TGA?: ", i.isNewTGA);
	if(i.isNewTGA) {
		writefln("\tExtenionAreaOffset:\t0x%x", i.ExtensionAreaOffset);
		writefln("\tDeveloperDirectoryOffset:\t0x%x", i.DeveloperDirectoryOffset);
		writeln("ExtensionArea:");
		writeln("\tSize:\t", i.ExtensionArea.Size);
		writeln("\tAuthorName:\t", i.ExtensionArea.AuthorName);
		foreach(size_t l; 0..4)
			writefln("\tAutorComments[%d]:\t%s",
				l,
				i.ExtensionArea.AuthorComments[l]);
		writeln("\tTimestamp:\t",
			i.ExtensionArea.Timestamp.toSimpleString);
		writeln("\tJobName:\t", i.ExtensionArea.JobName);
		writeln("\tJobTime:\t", i.ExtensionArea.JobTime.toString);
		writeln("\tSoftwareID:\t", i.ExtensionArea.SoftwareID);
		writeln("\tSoftwareVersion:\t",
			i.ExtensionArea.SoftwareVersion.toString);
		writeln("\tKeyColor:\t", i.ExtensionArea.KeyColor);
		writeln("\tAspectRatio:\t", i.ExtensionArea.AspectRatio.toString);
		writeln("\tGamma:\t", i.ExtensionArea.Gamma.toString);

		writefln("\tColorCorrectionOffset:\t0x%x",
			i.ExtensionArea.ColorCorrectionOffset);
		writefln("\tPostageStampOffset:\t0x%x",
			i.ExtensionArea.PostageStampOffset);
		writefln("\tScanLineOffset:\t0x%x",
			i.ExtensionArea.ScanLineOffset);
		writeln("\tAttributesType:\t",
			i.ExtensionArea.AttributesType);

		if(i.ExtensionArea.ScanLineOffset != 0) {
			writeln("ScanLineTable:");
			foreach(ref f; i.ScanLineTable)
				writeln("\t", f);
		}
	}
}
