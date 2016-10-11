/**
*	This module contains definitions of basic types
*/
module TArGeD.Defines;

import std.datetime : DateTime, TimeOfDay;
import std.array : appender;
import std.format : formattedWrite;
import std.stdio : File, SEEK_CUR, SEEK_SET;
import TArGeD.Util;

class TArGeDException : Exception {
	pure nothrow @nogc @safe this(string msg,
		string file = __FILE__,
		size_t line = __LINE__,
		Throwable next = null) {
			super(msg, file, line, next);
	}
}

/**
*	Is colour map presented?
*/
enum TGAColourMapType : ubyte { 
	NOT_PRESENT	= 0,
	PRESENT	= 1
}

/**
*	Image type
*/
enum TGAImageType : ubyte {
	NO_DATA	= 0,
	UNCOMPRESSED_MAPPED	= 1,	/// Uncompressed, colour map presented
	UNCOMPRESSED_TRUECOLOR	= 2,	/// Uncompressed, colour map not presented
	UNCOMPRESSED_GRAYSCALE	= 3,	/// Uncompressed, black and white
	COMPRESSED_MAPPED	= 9,	/// RLE encoded, colour map presented
	COMPRESSED_TRUECOLOR	= 10,	/// RLE encoded, colour map not presented
	COMPRESSED_GRAYSCALE	= 11	/// RLE encoded, black and white
}

/**
*	Header of every TARGA image
*/
struct TGAHeader {
	ubyte IDLength;	/// Length of `Image.ID`
	TGAColourMapType ColourMapType;	/// Type of colour map
	TGAImageType ImageType;	/// Type of the image
	ushort ColourMapOffset;	/// Index of first colour map entry
	ushort ColourMapLength;	/// Number of colour map entries
	ubyte ColourMapDepth;	/// Number of bits per colour map entry
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
	*		colourmapdepth	= number of bits per colour map entry
	*/
	this(TGAImageType i,
		ushort width,
		ushort height,
		ubyte pixeldepth = 32,
		ushort xorig = 0,
		ushort yorig = 0,
		ubyte colourmapdepth = 0) {
			this.ImageType = i;
			switch(this.ImageType) with(TGAImageType) {
				case UNCOMPRESSED_MAPPED:
				case COMPRESSED_MAPPED:
					this.ColourMapType = TGAColourMapType.PRESENT;
					break;
				default:
					this.ColourMapType = TGAColourMapType.NOT_PRESENT;
					break;
			}
			this.Width = width;
			this.Height = height;
			this.PixelDepth = pixeldepth;
			this.XOrigin = xorig;
			this.YOrigin = yorig;
			this.ColourMapDepth = colourmapdepth;
		}

	/**
	*	Parses header of file
	*/
	this(ref File f) {
		f.seek(0, SEEK_SET);
		this.IDLength	= f.readFile!(typeof(TGAHeader.IDLength));
		this.ColourMapType	=
			f.readFile!(typeof(TGAHeader.ColourMapType));
		this.ImageType	= f.readFile!(typeof(TGAHeader.ImageType));
		this.ColourMapOffset	=
			f.readFile!(typeof(TGAHeader.ColourMapOffset));
		this.ColourMapLength	=
			f.readFile!(typeof(TGAHeader.ColourMapLength));
		this.ColourMapDepth	=
			f.readFile!(typeof(TGAHeader.ColourMapDepth));
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

	/**
	*	Version constructor
	*/
	this(ushort n, char l) {
		this.Number = cast(float) n / 100;
		this.Letter = l;
	}
	/// ditto
	this(ref File f) {
		this(f.readFile!(ushort), f.readFile!(char));
	}

	/**
	*	Returns: formatted version
	*/
	string toString() {
		auto a = appender!string();
		a.formattedWrite("%.2f%s",
			this.Number,
			this.Letter);
		return a.data;
	}
}

/**
*	Represents aspect ratio
*/
struct TGARatio {
	/**
	*	Aspect ratio represented as Numerator:Denominator
	*	---
	*	Numerator = 16;
	*	Denominator = 9;
	*	// Aspect ratio is 16:9
	*	---
	*/
	ushort Numerator;
	/// ditto
	ushort Denominator;

	this(ushort n, ushort d) {
		this.Numerator = n;
		this.Denominator = d;
	}

	this(ref File f) {
		this(f.readFile!(ushort), f.readFile!(ushort));
	}


	/**
	*	Returns: formatted aspect ratio
	*/
	string toString() {
		auto a = appender!string();
		a.formattedWrite("%d:%d",
			this.Numerator,
			this.Denominator);
		return a.data;
	}

	/**
	*	Returns: `false` if aspect ratio value not presented and should not be used
	*/
	bool isPresented() {
		return this.Denominator != 0;
	}
}

/**
*	Represents gamma value
*/
struct TGAGamma {
	/**
	*	Gamma represented as Numerator:Denominator
	*	---
	*	Numerator = 9;
	*	Denominator = 8;
	*	// Gamma is 9.8
	*	---
	*/
	ushort Numerator;
	/// ditto
	ushort Denominator;

	this(ushort n, ushort d) {
		this.Numerator = n;
		this.Denominator = d;
	}

	this(ref File f) {
		this(f.readFile!(ushort), f.readFile!(ushort));
	}

	/**
	*	Returns: formatted gamma value
	*/
	string toString() {
		auto a = appender!string();
		a.formattedWrite("%d.%d",
			this.Numerator,
			this.Denominator);
		return a.data;
	}

	/**
	*	Returns: `false` if gamma value not presented and should not be used
	*/
	bool isEnabled() {
		return this.Denominator != 0;
	}

	/**
	*	Gamma have to be in range of 0.0 to 10.0
	*	Returns: `false` if gamma value is not correct
	*/
	bool isCorrect() {
		return (this.Numerator <= 10 && this.Denominator == 0) ||
			(this.Numerator < 10);
	}
}

/**
*	Represents extension area
*/
struct TGAExtensionArea {
	ushort Size;	/// Size of extension area. Should be set to 495
	char[40] AuthorName;	/// Author of image
	char[80][4] AuthorComments;	/// comments in 4 lines of 80 characters
	DateTime Timestamp;	/// Date and time when image was saved
	char[40] JobName;	/// Job name or ID
	TimeOfDay JobTime;	/// Job elapsed time when image was saved
	char[40] SoftwareID;	/// Name of program, which created this image
	TGAVersion SoftwareVersion;	/// Version of program
	uint KeyColour;	/// Background colour. TODO
	TGARatio AspectRatio;	/// Aspect ratio
	TGAGamma Gamma;	/// Gamma value
	uint ColourCorrectionOffset;	/// Offset of colour correction table
	uint PostageStampOffset;	/// Offset of postage stamp image
	uint ScanLineOffset;	/// Offset of scan line table
	ubyte AttributesType; /// Type of alpha channel

	this(ref File f, uint extAreaOff) {
		f.seek(extAreaOff, SEEK_SET);
		this.Size	=
			f.readFile!(typeof(TGAExtensionArea.Size));
		if(this.Size != 495) {
			throw new TArGeDException("Bad ExtensionArea size");
		}
		this.AuthorName	=
			f.rawRead(new char[41])[0..40];
		foreach(size_t i; 0..4)
			this.AuthorComments[i]	=
				f.rawRead(new char[81])[0..80];
		ushort Month, Day, Year, Hour, Minute, Second;
		Month	= f.readFile!(ushort);
		Day	= f.readFile!(ushort);
		Year	= f.readFile!(ushort);
		Hour	= f.readFile!(ushort);
		Minute	= f.readFile!(ushort);
		Second	= f.readFile!(ushort);
		if((Year && Month && Day) != 0)
			this.Timestamp = DateTime(Year,
				Month,
				Day,
				Hour,
				Minute,
				Second);
		this.JobName	=
			f.rawRead(new char[41])[0..40];

		ushort H, M, S;
		H	= f.readFile!(ushort);
		M	= f.readFile!(ushort);
		S	= f.readFile!(ushort);
		if((H && M && S) != 0)
			this.JobTime	= TimeOfDay(H, M, S);

		
		this.SoftwareID	=
			f.rawRead(new char[41])[0..40];
		this.SoftwareVersion	= TGAVersion(f);
		this.KeyColour	=
			f.readFile!(typeof(TGAExtensionArea.KeyColour));
		this.AspectRatio	= TGARatio(f);
		this.Gamma	= TGAGamma(f);

		this.ColourCorrectionOffset	=
			f.readFile!(typeof(TGAExtensionArea.ColourCorrectionOffset));
		this.PostageStampOffset	=
			f.readFile!(typeof(TGAExtensionArea.PostageStampOffset));
		this.ScanLineOffset	=
			f.readFile!(typeof(TGAExtensionArea.ScanLineOffset));
		this.AttributesType	=
			f.readFile!(typeof(TGAExtensionArea.AttributesType));

//		if(this.ScanLineOffset != 0) {
//			f.seek(this.ExtensionArea.ScanLineOffset, SEEK_SET);
//			this.ScanLineTable.length = this.Header.Height;
//			foreach(ref i; this.ScanLineTable)
//				i	= f.readFile!(typeof(ScanLineTable[0]));
//		}
	}
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

/**
*	Represents a single pixel
*/
struct Pixel {
	/// Red, Green, Blue and Alpha
	ubyte R, G, B, A;

	/// Pixel constructor
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
	/// ditto
	void from32(in ubyte[4] data) {
		this.R = data[2];
		this.G = data[1];
		this.B = data[0];
		this.A = data[3];
	}
	/// ditto
	void from24(in ubyte[3] data) {
		this.R = data[2];
		this.G = data[1];
		this.B = data[0];
		this.A = 0xFF;
	}
	/// ditto
	void from16(in ubyte[2] data) {
		this.R = (data[1] & 0x7c) << 1;
		this.G = ((data[1] & 0x03) << 6) | ((data[0] & 0xE0) >> 2);
		this.B = (data[0] & 0x1F) << 3;
		this.A = (data[1] & 0x80) ? 0xFF : 0;
	}
	/// ditto
	void from8(in ubyte[1] data) {
		this.R = data[0];
		this.G = data[0];
		this.B = data[0];
		this.A = 0xFF;
	}
}

