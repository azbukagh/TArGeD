module TArGeD.Image;

import std.stdio;
import std.bitmanip : littleEndianToNative;
import TArGeD.Defines;
import TArGeD.Util;

private template CMapReader(string depth) {
	const char[] CMapReader = q{
	case } ~ depth ~ q{:
		ubyte[} ~ depth ~ q{/8] buf;
		} ~ "for(size_t i = 0; i < (this.Header.CMapLength - this.Header.CMapOffset); i++) {
			f.rawRead(buf);
			this.ColorMap[i] = Pixel(cast(ubyte["~ depth ~ "/8]) buf);
		}" ~ q{
		break;
	};
}

struct Image {
	TGAHeader Header;
	ubyte[] ID;
	Pixel[] ColorMap;
	Pixel[] Pixels;

	this(string filename) {
		this(File(filename, "rb"));
	}

	this(File f) {
		this.readHeader(f);
		this.readID(f);
		this.readColorMap(f);
	}

	void readHeader(ref File f) {
		this.Header.IDLength	= f.readFile!(typeof(Header.IDLength));
		this.Header.CMapType	= f.readFile!(typeof(Header.CMapType));
		this.Header.IType	= f.readFile!(typeof(Header.IType));
		this.Header.CMapOffset	= f.readFile!(typeof(Header.CMapOffset));
		this.Header.CMapLength	= f.readFile!(typeof(Header.CMapLength));
		this.Header.CMapDepth	= f.readFile!(typeof(Header.CMapDepth));
		this.Header.XOrigin	= f.readFile!(typeof(Header.XOrigin));
		this.Header.YOrigin	= f.readFile!(typeof(Header.YOrigin));
		this.Header.Width	= f.readFile!(typeof(Header.Width));
		this.Header.Height	= f.readFile!(typeof(Header.Height));
		this.Header.PixelDepth	= f.readFile!(typeof(Header.PixelDepth));
		this.Header.ImageDescriptor	=
			f.readFile!(typeof(Header.ImageDescriptor));
	}

	void readID(ref File f) {
		if(this.Header.IDLength) {
			this.ID = f.rawRead(new ubyte[this.Header.IDLength]);
		} else {
			this.ID = [];
		}
	}

	void readColorMap(ref File f) {
		if(this.Header.CMapType == ColorMapType.NOT_PRESENT) {
			this.ColorMap = [];
			return;
		}

		this.ColorMap.length = this.Header.CMapLength;

		f.seek(this.Header.CMapOffset * this.Header.CMapDepth,
			SEEK_CUR);

		ubyte[] buf = new ubyte[this.Header.CMapDepth/8];

		foreach(size_t i; 0..this.Header.CMapLength - this.Header.CMapOffset) {
			f.rawRead(buf);
			this.ColorMap[i] = Pixel(buf);
		}
	}

//	void readPixelData(ref File f) {
//		switch(this.Header.IType) with(ImageType) {
//			case UNCOMPRESSED_MAPPED:
//			case UNCOMPRESSED_TRUECOLOR:
//			case UNCOMPRESSED_GRAYSCALE:
//				readUncompressedPixelData(f);
//				break;
//			case COMPRESSED_MAPPED:
//			case COMPRESSED_TRUECOLOR:
//			case COMPRESSED_GRAYSCALE:
//				readCompressedPixelData(f);
//				break;
//			default:
//				break;
//		}
//	}

//	private void readUncompressedPixelData(ref File f) {
//		auto r = (this.Header.CMapType = ColorMapType.NOT_PRESENT)
//			? (ubyte[] d) => Pixel(d
//			: (ubyte[] d) => this.ColorMap[readArray!uint(b)];
//		this.Pixels.length = this.Header.Width * this.Header.Width;

//		ubyte[] buf 
//		foreach(ref p; this.Pixels) {
//			
//	}
//	private void readCompressedPixelData(ref File f) {
//	}
}

