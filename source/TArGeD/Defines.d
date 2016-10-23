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
		this.IDLength	= f.readFromFile!(typeof(TGAHeader.IDLength));
		this.ColourMapType	=
			f.readFromFile!(typeof(TGAHeader.ColourMapType));
		this.ImageType	= f.readFromFile!(typeof(TGAHeader.ImageType));
		this.ColourMapOffset	=
			f.readFromFile!(typeof(TGAHeader.ColourMapOffset));
		this.ColourMapLength	=
			f.readFromFile!(typeof(TGAHeader.ColourMapLength));
		this.ColourMapDepth	=
			f.readFromFile!(typeof(TGAHeader.ColourMapDepth));
		this.XOrigin	= f.readFromFile!(typeof(TGAHeader.XOrigin));
		this.YOrigin	= f.readFromFile!(typeof(TGAHeader.YOrigin));
		this.Width	= f.readFromFile!(typeof(TGAHeader.Width));
		this.Height	= f.readFromFile!(typeof(TGAHeader.Height));
		this.PixelDepth	= f.readFromFile!(typeof(TGAHeader.PixelDepth));
		this.ImageDescriptor	=
			f.readFromFile!(typeof(TGAHeader.ImageDescriptor));
	}

	void write(ref File f) {
		f.writeToFile(this.IDLength);
		f.writeToFile(this.ColourMapType);
		f.writeToFile(this.ImageType);
		f.writeToFile(this.ColourMapOffset);
		f.writeToFile(this.ColourMapLength);
		f.writeToFile(this.ColourMapDepth);
		f.writeToFile(this.XOrigin);
		f.writeToFile(this.YOrigin);
		f.writeToFile(this.Width);
		f.writeToFile(this.Height);
		f.writeToFile(this.PixelDepth);
		f.writeToFile(this.ImageDescriptor);
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
		this(f.readFromFile!(ushort), f.readFromFile!(char));
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

	void write(ref File f) {
		try {
			f.writeToFile((this.Number * 100).to!ushort);
		} catch {
			f.writeToFile(to!ushort(100));
		}
		f.write(this.Letter);
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
		this(f.readFromFile!(ushort), f.readFromFile!(ushort));
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

	void write(ref File f) {
		f.writeToFile(this.Numerator);
		f.writeToFile(this.Denominator);
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
		this(f.readFromFile!(ushort), f.readFromFile!(ushort));
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

	void write(ref File f) {
		f.writeToFile(this.Numerator);
		f.writeToFile(this.Denominator);
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
			f.readFromFile!(typeof(TGAExtensionArea.Size));
		if(this.Size != 495) {
			throw new TArGeDException("Bad ExtensionArea size");
		}
		this.AuthorName	=
			f.rawRead(new char[41])[0..40];
		foreach(size_t i; 0..4)
			this.AuthorComments[i]	=
				f.rawRead(new char[81])[0..80];
		ushort Month, Day, Year, Hour, Minute, Second;
		Month	= f.readFromFile!(ushort);
		Day	= f.readFromFile!(ushort);
		Year	= f.readFromFile!(ushort);
		Hour	= f.readFromFile!(ushort);
		Minute	= f.readFromFile!(ushort);
		Second	= f.readFromFile!(ushort);
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
		H	= f.readFromFile!(ushort);
		M	= f.readFromFile!(ushort);
		S	= f.readFromFile!(ushort);
		if((H && M && S) != 0)
			this.JobTime	= TimeOfDay(H, M, S);

		
		this.SoftwareID	=
			f.rawRead(new char[41])[0..40];
		this.SoftwareVersion	= TGAVersion(f);
		this.KeyColour	=
			f.readFromFile!(typeof(TGAExtensionArea.KeyColour));
		this.AspectRatio	= TGARatio(f);
		this.Gamma	= TGAGamma(f);

		this.ColourCorrectionOffset	=
			f.readFromFile!(typeof(TGAExtensionArea.ColourCorrectionOffset));
		this.PostageStampOffset	=
			f.readFromFile!(typeof(TGAExtensionArea.PostageStampOffset));
		this.ScanLineOffset	=
			f.readFromFile!(typeof(TGAExtensionArea.ScanLineOffset));
		this.AttributesType	=
			f.readFromFile!(typeof(TGAExtensionArea.AttributesType));

//		if(this.ScanLineOffset != 0) {
//			f.seek(this.ExtensionArea.ScanLineOffset, SEEK_SET);
//			this.ScanLineTable.length = this.Header.Height;
//			foreach(ref i; this.ScanLineTable)
//				i	= f.readFromFile!(typeof(ScanLineTable[0]));
//		}
	}

	uint write(ref File f) {
		uint ret = cast(uint) f.tell;
		f.writeToFile(this.Size);
		f.write(this.AuthorName, "\0");
		foreach(size_t i; 0..4)
			f.write(this.AuthorComments[i], "\0");
		f.writeToFile(this.Timestamp.month.to!ushort);
		f.writeToFile(this.Timestamp.day.to!ushort);
		f.writeToFile(this.Timestamp.year.to!ushort);
		f.writeToFile(this.Timestamp.hour.to!ushort);
		f.writeToFile(this.Timestamp.minute.to!ushort);
		f.writeToFile(this.Timestamp.second.to!ushort);
		f.write(this.JobName, "\0");
		f.writeToFile(this.JobTime.hour.to!ushort);
		f.writeToFile(this.JobTime.minute.to!ushort);
		f.writeToFile(this.JobTime.second.to!ushort);
		f.write(this.SoftwareID, "\0");
		this.SoftwareVersion.write(f);
		f.writeToFile(this.KeyColour);
		this.AspectRatio.write(f);
		this.Gamma.write(f);
		f.writeToFile(cast(uint) 0);	//	TODO
		f.writeToFile(cast(uint) 0);	// Some offsets
		f.writeToFile(cast(uint) 0);	//
		f.writeToFile(this.AttributesType);
		return ret;
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

	void write(ref File f, size_t depth) {
		switch(depth) {
			case 32:
				f.rawWrite(this.to32);
				break;
			case 24:
				f.rawWrite(this.to24);
				break;
			case 16:
				f.rawWrite(this.to16);
				break;
			case 8:
				f.rawWrite(this.to8);
				break;
			default:
				break;
		}
	}

	ubyte[4] to32() {
		return [
			this.B,
			this.G,
			this.R,
			this.A
		];
	}

	ubyte[3] to24() {
		return [
			this.B,
			this.G,
			this.R
		];
	}

	ubyte[2] to16() {
		return [
			cast(ubyte) ((this.G << 2) | (this.B >> 3)),
			cast(ubyte) ((this.A & 0x80) |
				(this.R >> 1) | (this.G >> 6))
		];
	}

	ubyte[1] to8() {
		return [
			cast(ubyte) (this.R + this.G + this.B) / 3
		];
	}
}

