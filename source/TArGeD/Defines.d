/**
*	This module contains definitions of basic types
*/
module TArGeD.Defines;

import std.datetime : DateTime, TimeOfDay;
import std.array : appender;
import std.format : formattedWrite;
import std.stdio : File, SEEK_CUR, SEEK_SET;
import std.conv : to;
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
	*	Parses header of file
	*/
	this(ref ubyte* c, ubyte* s, ubyte* e) {
		this.IDLength	= c.readValue!(typeof(TGAHeader.IDLength))(s, e);
		this.ColourMapType	=
			 c.readValue!(typeof(TGAHeader.ColourMapType))(s, e);
		this.ImageType	= c.readValue!(typeof(TGAHeader.ImageType))(s, e);
		this.ColourMapOffset	=
			c.readValue!(typeof(TGAHeader.ColourMapOffset))(s, e);
		this.ColourMapLength	=
			c.readValue!(typeof(TGAHeader.ColourMapLength))(s, e);
		this.ColourMapDepth	=
			c.readValue!(typeof(TGAHeader.ColourMapDepth))(s, e);
		this.XOrigin	= c.readValue!(typeof(TGAHeader.XOrigin))(s, e);
		this.YOrigin	= c.readValue!(typeof(TGAHeader.YOrigin))(s, e);
		this.Width	= c.readValue!(typeof(TGAHeader.Width))(s, e);
		this.Height	= c.readValue!(typeof(TGAHeader.Height))(s, e);
		this.PixelDepth	= c.readValue!(typeof(TGAHeader.PixelDepth))(s, e);
		this.ImageDescriptor	=
			c.readValue!(typeof(TGAHeader.ImageDescriptor))(s, e);
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
	this(ref ubyte* c, ubyte* s, ubyte* e) {
		this(
			c.readValue!(ushort)(s, e),
			c.readValue!(char)(s, e));
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

	this(ref ubyte* c, ubyte* s, ubyte* e) {
		this(
			c.readValue!(ushort)(s, e),
			c.readValue!(ushort)(s, e)
		);
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

	this(ref ubyte* c, ubyte* s, ubyte* e) {
		this(
			c.readValue!(ushort)(s, e),
			c.readValue!(ushort)(s, e)
		);
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
	bool isPresented() {
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

	this(ref ubyte* c, ref ubyte* s, ref ubyte* e) {
		this.Size	=
			c.readValue!(typeof(TGAExtensionArea.Size))(s, e);
		if(this.Size != 495) {
			throw new TArGeDException("Bad ExtensionArea size");
		}
		this.AuthorName = c.readArray!(typeof(this.AuthorName))(s, e);
		++c;
		foreach(size_t i; 0..4) {
			this.AuthorComments[i] = c.readArray!(typeof(this.AuthorComments[i]))(s, e);
			++c;
		}

		ushort Month, Day, Year, Hour, Minute, Second;
		Month	= c.readValue!(ushort)(s, e);
		Day	= c.readValue!(ushort)(s, e);
		Year	= c.readValue!(ushort)(s, e);
		Hour	= c.readValue!(ushort)(s, e);
		Minute	= c.readValue!(ushort)(s, e);
		Second	= c.readValue!(ushort)(s, e);
		if((Year && Month && Day) != 0)
			this.Timestamp = DateTime(Year,
				Month,
				Day,
				Hour,
				Minute,
				Second);
		this.JobName = c.readArray!(typeof(this.JobName))(s, e);
		++c;

		ushort H, M, S;
		H	= c.readValue!(ushort)(s, e);
		M	= c.readValue!(ushort)(s, e);
		S	= c.readValue!(ushort)(s, e);
		if((H && M && S) != 0)
			this.JobTime	= TimeOfDay(H, M, S);


		this.SoftwareID = c.readArray!(typeof(this.SoftwareID))(s, e);
		++c;
		this.SoftwareVersion	= TGAVersion(c, s, e);
		this.KeyColour	=
			c.readValue!(typeof(TGAExtensionArea.KeyColour))(s, e);
		this.AspectRatio	= TGARatio(c, s, e);
		this.Gamma	= TGAGamma(c, s, e);

		this.ColourCorrectionOffset	=
			c.readValue!(typeof(TGAExtensionArea.ColourCorrectionOffset))(s, e);
		this.PostageStampOffset	=
			c.readValue!(typeof(TGAExtensionArea.PostageStampOffset))(s, e);
		this.ScanLineOffset	=
			c.readValue!(typeof(TGAExtensionArea.ScanLineOffset))(s, e);
		this.AttributesType	=
			c.readValue!(typeof(TGAExtensionArea.AttributesType))(s, e);

//		if(this.ScanLineOffset != 0) {
//			f.seek(this.ExtensionArea.ScanLineOffset, SEEK_SET);
//			this.ScanLineTable.length = this.Header.Height;
//			foreach(ref i; this.ScanLineTable)
//				i	= f.readFromFile!(typeof(ScanLineTable[0]));
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

	this(ref ubyte* c, ubyte* s, ubyte* e, ubyte depth) {
		switch(depth) {
			case 32:
				this.r32(c, s, e);
				break;
			case 24:
				this.r24(c, s, e);
				break;
			case 16:
				this.r16(c, s, e);
				break;
			case 8:
				this.r8(c, s, e);
				break;
			default:
				throw new TArGeDException("Wrong pixel depth");
		}
	}

	void r32(ref ubyte* c, ubyte* s, ubyte* e)
	in {
		assert(c + 3 <= e, "End of image reached");
		assert(c >= s, "Wrong pointer");
	} body {
		this.R = c[2];
		this.G = c[1];
		this.B = c[0];
		this.A = c[3];
		c += 4;
	}

	void r24(ref ubyte* c, ubyte* s, ubyte* e)
	in {
		assert(c + 2 <= e, "End of image reached");
		assert(c >= s, "Wrong pointer");
	} body {
		this.R = c[2];
		this.G = c[1];
		this.B = c[0];
		this.A = 0xFF;
		c += 3;
	}

	void r16(ref ubyte* c, ubyte* s, ubyte* e)
	in {
		assert(c + 1 <= e, "End of image reached");
		assert(c >= s, "Wrong pointer");
	} body {
		this.R = (c[1] & 0x7c) << 1;
		this.G = ((c[1] & 0x03) << 6) | ((c[0] & 0xE0) >> 2);
		this.B = (c[0] & 0x1F) << 3;
		this.A = (c[1] & 0x80) ? 0xFF : 0;
		c += 2;
	}

	void r8(ref ubyte* c, ubyte* s, ubyte* e)
	in {
		assert(c <= e, "End of image reached");
		assert(c >= s, "Wrong pointer");
	} body {
		this.R = c[0];
		this.G = c[0];
		this.B = c[0];
		this.A = 0xFF;

		++c;
	}
}
