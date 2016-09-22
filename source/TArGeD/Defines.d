module TArGeD.Defines;

import std.datetime : DateTime, TimeOfDay;
import std.array : appender;
import std.format : formattedWrite;

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

struct Version {
	ushort Number;
	char Letter;

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
	Version SoftwareVersion;
	uint KeyColor;
	TGARatio AspectRatio;
	TGAGamma Gamma;
	uint ColorCorrectionOffset;
	uint PostageStampOffset;
	uint ScanLineOffset;
	ubyte AttributesType; // TODO: handle it
}

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

