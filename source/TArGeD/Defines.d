/**
*	This module contains definitions of basic types
*/
module TArGeD.Defines;

import std.datetime : DateTime, TimeOfDay;
import std.array : appender;
import std.format : formattedWrite;
import std.stdio;
import TArGeD.Util;
import std.array;

/**
*	Is color map presented?
*/
enum ColorMapType : ubyte { 
	NOT_PRESENT	= 0,
	PRESENT	= 1
}

/**
*	Image type
*/
enum ImageType : ubyte {
	NO_DATA	= 0,
	UNCOMPRESSED_MAPPED	= 1,	/// Uncompressed, color map presented
	UNCOMPRESSED_TRUECOLOR	= 2,	/// Uncompressed, color map not presented
	UNCOMPRESSED_GRAYSCALE	= 3,	/// Uncompressed, black and white
	COMPRESSED_MAPPED	= 9,	/// RLE encoded, color map presented
	COMPRESSED_TRUECOLOR	= 10,	/// RLE encoded, color map not presented
	COMPRESSED_GRAYSCALE	= 11	/// RLE encoded, black and white
}

/**
*	Header of every TARGA image
*/
struct TGAHeader {
	ubyte IDLength;	/// Length of `Image.ID`
	ColorMapType CMapType;	/// Type of color map
	ImageType IType;	/// Type of the image
	ushort CMapOffset;	/// Index of first color map entry
	ushort CMapLength;	/// Number of color map entries
	ubyte CMapDepth;	/// Number of bits per color map entry
	ushort XOrigin;	/// horizontal coordinate for the lower left corner of the image
	ushort YOrigin;	/// vertical coordinate for the lower left corner of the image
	ushort Width;	/// Width of the image in pixels
	ushort Height;	/// Height of the image in pixels
	ubyte PixelDepth;	/// Number of bits per pixel
	ubyte ImageDescriptor;	/// TODO

	/**
	*	Creates header
	*	Params:
	*		i	= type of the image
	*		width	= width in pixels
	*		height	= height in pixels
	*		pixeldepth	= number of bits per pixel
	*		xorig	= horizontal coordinate for the lower left corner of the image
	*		yorig	= vertical coordinate for the lower left corner of the image
	*		colormapdepth	= number of bits per color map entry
	*/
	this(ImageType i,
		ushort width,
		ushort height,
		ubyte pixeldepth = 32,
		ushort xorig = 0,
		ushort yorig = 0,
		ubyte colormapdepth = 0) {
			this.IType = i;
			switch(this.IType) with(ImageType) {
				case UNCOMPRESSED_MAPPED:
				case COMPRESSED_MAPPED:
					this.CMapType = ColorMapType.PRESENT;
					break;
				default:
					this.CMapType = ColorMapType.NOT_PRESENT;
					break;
			}
			this.Width = width;
			this.Height = height;
			this.PixelDepth = pixeldepth;
			this.XOrigin = xorig;
			this.YOrigin = yorig;
			this.CMapDepth = colormapdepth;
		}

	/**
	*	Parses header of file
	*/
	this(ref File f) {
		f.seek(0, SEEK_SET);
		this.IDLength	= f.readFile!(typeof(TGAHeader.IDLength));
		this.CMapType	= f.readFile!(typeof(TGAHeader.CMapType));
		this.IType	= f.readFile!(typeof(TGAHeader.IType));
		this.CMapOffset	= f.readFile!(typeof(TGAHeader.CMapOffset));
		this.CMapLength	= f.readFile!(typeof(TGAHeader.CMapLength));
		this.CMapDepth	= f.readFile!(typeof(TGAHeader.CMapDepth));
		this.XOrigin	= f.readFile!(typeof(TGAHeader.XOrigin));
		this.YOrigin	= f.readFile!(typeof(TGAHeader.YOrigin));
		this.Width	= f.readFile!(typeof(TGAHeader.Width));
		this.Height	= f.readFile!(typeof(TGAHeader.Height));
		this.PixelDepth	= f.readFile!(typeof(TGAHeader.PixelDepth));
		this.ImageDescriptor	=
			f.readFile!(typeof(TGAHeader.ImageDescriptor));
	}
}

/**
*	Represents version
*/
struct TGAVersion {
	float Number;
	char Letter;

	this(ushort n, char l) {
		this.Number = n / 100;
		this.Letter = l;
	}

	this(ref File f) {
		this(f.readFile!(ushort), f.readFile!(char));
	}

	string toString() {
		auto a = appender!string();
		a.formattedWrite("%.2f%s",
			cast(float) this.Number / 100,
			this.Letter);
		return a.data;
	}
}

struct TGARatio {
	ushort Numerator;
	ushort Denominator;
	string toString() {
		auto a = appender!string();
		a.formattedWrite("%d:%d",
			this.Numerator,
			this.Denominator);
		return a.data;
	}

	bool isEnabled() {
		return this.Denominator != 0;
	}
}

struct TGAGamma {
	ushort Numerator;
	ushort Denominator;
	string toString() {
		auto a = appender!string();
		a.formattedWrite("%d.%d",
			this.Numerator,
			this.Denominator);
		return a.data;
	}

	bool isEnabled() {
		return this.Denominator != 0;
	}

	bool isCorrect() {
		return (this.Numerator <= 10 && this.Denominator == 0) ||
			(this.Numerator < 10);
	}
}

struct TGAExtensionArea {
	ushort Size;
	char[40] AuthorName;
	char[80][4] AuthorComments;
	DateTime Timestamp;
	char[40] JobName;
	TimeOfDay JobTime;
	char[40] SoftwareID;
	TGAVersion SoftwareVersion;
	uint KeyColor;
	TGARatio AspectRatio;
	TGAGamma Gamma;
	uint ColorCorrectionOffset;
	uint PostageStampOffset;
	uint ScanLineOffset;
	ubyte AttributesType; // TODO: handle it
}

/*
struct DeveloperField {
	ushort Tag;
	uint Offset;
	uint Size;
}

struct TGADeveloperArea {
	ushort Size;
	DeveloperField[] Data;
}
*/

struct Pixel {
	ubyte R, G, B, A;

	this(in ubyte[] data) {
		switch(data.length) {
			case 4:
				from32(data[0..4]);
				break;
			case 3:
				from24(data[0..3]);
				break;
			case 2:
				from16(data[0..2]);
				break;
			case 1:
				from8(data[0..1]);
				break;
			default:
				break;
		}
	}

	void from32(in ubyte[4] data, ) {
		this.R = data[2];
		this.G = data[1];
		this.B = data[0];
		this.A = data[3];
	}

	void from24(in ubyte[3] data) {
		this.R = data[2];
		this.G = data[1];
		this.B = data[0];
		this.A = 0xFF;
	}

	void from16(in ubyte[2] data) {
		this.R = (data[1] & 0x7c) << 1;
		this.G = ((data[1] & 0x03) << 6) | ((data[0] & 0xE0) >> 2);
		this.B = (data[0] & 0x1F) << 3;
		this.A = (data[1] & 0x80) ? 0xFF : 0;
	}

	void from8(in ubyte[1] data) {
		this.R = data[0];
		this.G = data[0];
		this.B = data[0];
		this.A = 0xFF;
	}
}

