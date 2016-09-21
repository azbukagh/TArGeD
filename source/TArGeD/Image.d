module TArGeD.Image;

import std.stdio;
import std.bitmanip : littleEndianToNative;
import TArGeD.Defines;
import TArGeD.Util;
import std.string : fromStringz;
import std.datetime : DateTime;

struct Image {
	TGAHeader Header;
	ubyte[] ID;
	Pixel[] ColorMap;
	Pixel[] Pixels;
	ulong ExtensionAreaOffset;
	ulong DeveloperDirectoryOffset;
	TGAExtensionArea ExtensionArea;

	private {
		bool newFormat;
	}

	bool isNewTGA() {
		return this.newFormat;
	}

	this(string filename) {
		this(File(filename, "rb"));
	}

	this(File f) {
		this.readFooter(f);
		this.readHeader(f);
		this.readID(f);
		this.readColorMap(f);
		this.readPixelData(f);
		if(this.isNewTGA && ExtensionAreaOffset != 0)
			this.readExtensionArea(f);
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

	void readPixelData(ref File f) {
		switch(this.Header.IType) with(ImageType) {
			case UNCOMPRESSED_MAPPED:
			case UNCOMPRESSED_TRUECOLOR:
			case UNCOMPRESSED_GRAYSCALE:
				readUncompressedPixelData(f);
				break;
			case COMPRESSED_MAPPED:
			case COMPRESSED_TRUECOLOR:
			case COMPRESSED_GRAYSCALE:
				readCompressedPixelData(f);
				break;
			default:
				break;
		}
	}

	private void readUncompressedPixelData(ref File f) {
		auto r = (this.Header.CMapType == ColorMapType.PRESENT)
			? delegate (ubyte[] d) =>
				this.ColorMap[readArray!uint(d)]
			: delegate (ubyte[] d) =>
				Pixel(d);
		this.Pixels.length = this.Header.Width * this.Header.Width;

		ubyte[] buf = new ubyte[this.Header.PixelDepth/8];
		foreach(ref p; this.Pixels) {
			f.rawRead(buf);
			p = r(buf);
		}
	}

	private void readCompressedPixelData(ref File f) {
		auto r = (this.Header.CMapType == ColorMapType.PRESENT)
			? delegate (ubyte[] d) =>
				this.ColorMap[readArray!uint(d)]
			: delegate (ubyte[] d) =>
				Pixel(d);
		this.Pixels.length = this.Header.Width * this.Header.Width;

		ubyte[] buf = new ubyte[this.Header.PixelDepth/8+1];
		size_t i;
		while(i < this.Header.Width * this.Header.Height) {
			f.rawRead(buf);
			size_t rep = buf[0] & 0x7F;
			this.Pixels[i] = r(buf[0..this.Header.PixelDepth/8]);
			i++;
			if(buf[0] & 0x80) {
				for(size_t j = 0; j < rep; j++, i++)
					this.Pixels[i] =
						r(buf[1 .. this.Header.PixelDepth/8+1]);
			} else {
				for(size_t j=0; j < rep; j++, i++) {
					f.rawRead(
						buf[0..this.Header.PixelDepth/8]
					);
					this.Pixels[i] =
						r(buf[0..this.Header.PixelDepth/8]);
				}
			}
		}
	}

	void readFooter(ref File f) {
		f.seek(-26, SEEK_END);
		ubyte[26] buf;
		f.rawRead(buf);
		this.newFormat = (buf[8..24] == "TRUEVISION-XFILE" &&
			buf[24] == '.');
		if(this.isNewTGA) {
			this.ExtensionAreaOffset = readArray!ulong(buf[0..4]);
			this.DeveloperDirectoryOffset =
				readArray!ulong(buf[4..8]);
		}
		f.seek(0, SEEK_SET);
	}

	void readExtensionArea(ref File f) {
		this.ExtensionArea.Size	=
			f.readFile!(typeof(TGAExtensionArea.Size));
		if(this.ExtensionArea.Size != 495) {
			// Not TGA v2.0
		}
		this.ExtensionArea.AuthorName	=
			f.readFile!(char[41]).fromStringz;
		foreach(size_t i; 0..4)
			this.ExtensionArea.AuthorComments[i]	=
				f.readFile!(char[81]).fromStringz;
		ushort Month, Day, Year, Hour, Minute, Second;
		Month	= f.readFile!(ushort);
		Day	= f.readFile!(ushort);
		Year	= f.readFile!(ushort);
		Hour	= f.readFile!(ushort);
		Minute	= f.readFile!(ushort);
		Second	= f.readFile!(ushort);
		this.ExtensionArea.Timestamp = DateTime(Year,
			Month,
			Day,
			Hour,
			Minute,
			Second);
		this.ExtensionArea.JobName	=
			f.readFile!(char[41]).fromStringz;

		f.readFile!(ushort); // |
		f.readFile!(ushort); //  > JobTime
		f.readFile!(ushort); // |

		this.ExtensionArea.SoftwareID	=
			f.readFile!(char[41]).fromStringz;
		this.ExtensionArea.SoftwareVersion	= Version(
			f.readFile!(typeof(Version.Number)),
			f.readFile!(typeof(Version.Letter))
		);
		this.ExtensionArea.KeyColor	=
			f.readFile!(typeof(TGAExtensionArea.KeyColor));
		
	}
}

