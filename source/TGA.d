module TGA;

import std.stdio;
import std.bitmanip : littleEndianToNative;

enum ColorMapType : ubyte { 
	NOT_PRESENT	= 0,
	PRESENT	= 1
}

enum ImageType : ubyte {
	NO_DATA	= 0,
	UNCOMPRESSED_MAPPED	= 1,
	UNCOMPRESSED_TRUECOLOR	= 2,
	UNCOMPRESSED_GRAYSCALE	= 3,
	COMPRESSED_MAPPED	= 9,
	COMPRESSED_TRUECOLOR	= 10,
	COMPRESSED_GRAYSCALE	= 11
}

struct TGAHeader {
	ubyte IDLength;
	ColorMapType CMapType;
	ImageType IType;
	ushort CMapOffset;
	ushort CMapLength;
	ubyte CMapDepth;
	ushort XOrigin;
	ushort YOrigin;
	ushort Width;
	ushort Height;
	ubyte PixelDepth;
	ubyte ImageDescriptor;
}

struct Pixel {
	ubyte R, G, B, A;

	this(in ubyte[4] data, ) {
		this.R = data[2];
		this.G = data[1];
		this.B = data[0];
		this.A = data[3];
	}

	this(in ubyte[3] data) {
		this.R = data[2];
		this.G = data[1];
		this.B = data[0];
		this.A = 0xFF;
	}

	this(in ubyte[2] data) {
		this.R = (data[1] & 0x7c) << 1;
		this.G = ((data[1] & 0x03) << 6) | ((data[0] & 0xE0) >> 2);
		this.B = (data[0] & 0x1F) << 3;
		this.A = (data[1] & 0x80) ? 0xFF : 0;
	}

	this(in ubyte[1] data) {
		this.R = data[0];
		this.G = data[0];
		this.B = data[0];
		this.A = 0xFF;
	}
}

private T read(T)(ref File f) {
	ubyte[T.sizeof] buffer;
	f.rawRead(buffer);
	return littleEndianToNative!T(buffer);
}

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
		this.Header.IDLength	= f.read!(typeof(Header.IDLength));
		this.Header.CMapType	= f.read!(typeof(Header.CMapType));
		this.Header.IType	= f.read!(typeof(Header.IType));
		this.Header.CMapOffset	= f.read!(typeof(Header.CMapOffset));
		this.Header.CMapLength	= f.read!(typeof(Header.CMapLength));
		this.Header.CMapDepth	= f.read!(typeof(Header.CMapDepth));
		this.Header.XOrigin	= f.read!(typeof(Header.XOrigin));
		this.Header.YOrigin	= f.read!(typeof(Header.YOrigin));
		this.Header.Width	= f.read!(typeof(Header.Width));
		this.Header.Height	= f.read!(typeof(Header.Height));
		this.Header.PixelDepth	= f.read!(typeof(Header.PixelDepth));
		this.Header.ImageDescriptor	=
			f.read!(typeof(Header.ImageDescriptor));
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

		switch(this.Header.CMapDepth) {
			mixin(CMapReader!("32"));
			mixin(CMapReader!("24"));
			mixin(CMapReader!("16"));
			mixin(CMapReader!("8"));
			default:
				break;
		}
	}

	void readPixelData(ref File f) {
	
	
	}
}

