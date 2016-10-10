/**
*	Image reader
*/
module TArGeD.Old.Image;

import std.stdio;
import TArGeD.Old.Defines;
import TArGeD.Old.Util;
import std.datetime : DateTime, TimeOfDay;

/**
*	Thrown if errors happen.
*/
class TArGeDException : Exception {
	pure nothrow @nogc @safe this(string msg,
		string file = __FILE__,
		size_t line = __LINE__,
		Throwable next = null) {
			super(msg, file, line, next);
	}
}

/**
*	Reads TARGA image
*/
struct Image {
	TGAHeader Header;	/// Header of the image
	ubyte[] ID;	/// Identifying information about the image
	/**
	*	Color map data, if `Header.CMapType = ColorMapType.PRESENT`
	*/
	Pixel[] ColorMap;
	Pixel[] Pixels;	/// Contains `Header.Width*Header.Height` pixels
	ulong ExtensionAreaOffset;	/// Offset of extension area
	ulong DeveloperDirectoryOffset;	/// Offset of developer area
	/**
	*	Extension area, if `Image.isNewTGA && (Image.ExtensionAreaOffset != 0)`
	*/
	TGAExtensionArea ExtensionArea;
	/**
	*	Scan line table. Empty if no scan line table presented
	*/
	uint[] ScanLineTable;

	private {
		bool newFormat;
	}

	/**
	*	New TARGA image format contains Developer area and Extension area
	*/
	bool isNewTGA() {
		return this.newFormat;
	}

	/**
	*	Reads image
	*/
	this(string filename) {
		this(File(filename, "rb"));
	}
	/// ditto
	this(File f) {
		this.readFooter(f);
		this.Header = TGAHeader(f);
		this.readID(f);
		this.readColorMap(f);
		this.readPixelData(f);
		if(this.isNewTGA && (ExtensionAreaOffset != 0))
			this.readExtensionArea(f);
	}

	private void readID(ref File f) {
		if(this.Header.IDLength) {
			this.ID = f.rawRead(new ubyte[this.Header.IDLength]);
		} else {
			this.ID = [];
		}
	}

	private void readColorMap(ref File f) {
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

	private void readPixelData(ref File f) {
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
				throw new TArGeDException(
					"Wrong image type"
				);
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

	private void readFooter(ref File f) {
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
	}

	private void readExtensionArea(ref File f) {
		f.seek(this.ExtensionAreaOffset, SEEK_SET);
		this.ExtensionArea.Size	=
			f.readFile!(typeof(TGAExtensionArea.Size));
		if(this.ExtensionArea.Size != 495) {
			throw new TArGeDException("Bad ExtensionArea size");
		}
		this.ExtensionArea.AuthorName	=
			f.rawRead(new char[41])[0..40];
		foreach(size_t i; 0..4)
			this.ExtensionArea.AuthorComments[i]	=
				f.rawRead(new char[81])[0..80];
		ushort Month, Day, Year, Hour, Minute, Second;
		Month	= f.readFile!(ushort);
		Day	= f.readFile!(ushort);
		Year	= f.readFile!(ushort);
		Hour	= f.readFile!(ushort);
		Minute	= f.readFile!(ushort);
		Second	= f.readFile!(ushort);
		if((Year && Month && Day) != 0)
			this.ExtensionArea.Timestamp = DateTime(Year,
				Month,
				Day,
				Hour,
				Minute,
				Second);
		this.ExtensionArea.JobName	=
			f.rawRead(new char[41])[0..40];

		ushort H, M, S;
		H	= f.readFile!(ushort);
		M	= f.readFile!(ushort);
		S	= f.readFile!(ushort);
		if((H && M && S) != 0)
			this.ExtensionArea.JobTime	= TimeOfDay(H, M, S);

		this.ExtensionArea.SoftwareID	=
			f.rawRead(new char[41])[0..40];
		this.ExtensionArea.SoftwareVersion	= TGAVersion(f);
		this.ExtensionArea.KeyColor	=
			f.readFile!(typeof(TGAExtensionArea.KeyColor));
		this.ExtensionArea.AspectRatio	= TGARatio(
			f.readFile!(typeof(TGARatio.Numerator)),
			f.readFile!(typeof(TGARatio.Denominator))
		);
		this.ExtensionArea.Gamma	= TGAGamma(
			f.readFile!(typeof(TGAGamma.Numerator)),
			f.readFile!(typeof(TGAGamma.Denominator))
		);

		this.ExtensionArea.ColorCorrectionOffset	=
			f.readFile!(typeof(TGAExtensionArea.ColorCorrectionOffset));
		this.ExtensionArea.PostageStampOffset	=
			f.readFile!(typeof(TGAExtensionArea.PostageStampOffset));
		this.ExtensionArea.ScanLineOffset	=
			f.readFile!(typeof(TGAExtensionArea.ScanLineOffset));
		this.ExtensionArea.AttributesType	=
			f.readFile!(typeof(TGAExtensionArea.AttributesType));

		if(this.ExtensionArea.ScanLineOffset != 0) {
			f.seek(this.ExtensionArea.ScanLineOffset, SEEK_SET);
			this.ScanLineTable.length = this.Header.Height;
			foreach(ref i; this.ScanLineTable)
				i	= f.readFile!(typeof(ScanLineTable[0]));
		}
	}
}

