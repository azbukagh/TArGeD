module TArGeD.Image;

import TArGeD.Defines;
import TArGeD.Util;
import std.stdio : File, SEEK_CUR, SEEK_END;
import std.traits : isArray, isImplicitlyConvertible;
import std.datetime : DateTime, TimeOfDay;

class Image {
	private {
		TGAHeader ImageHeader;
		ubyte[] ImageID;
		Pixel[] ImageColourMap;
		Pixel[] ImagePixels;
		uint ImageExtAreaOffset;
		uint ImageDevDirOffset;
		TGAExtensionArea ImageExtArea;

		bool isImageNewFormat;
	}

	this(string filename) {
		this(File(filename, "rb"));
	}

	this(File f) {
		this.readFooter(f,
			this.ImageExtAreaOffset,
			this.ImageDevDirOffset);
		this.ImageHeader = TGAHeader(f);
		this.readID(f, this.ImageHeader.IDLength, this.ImageID);
		this.readColourMap(f,
			this.ImageHeader,
			this.ImageColourMap);
		this.readPixelData(f,
			this.ImageHeader,
			this.ImageColourMap,
			this.ImagePixels);
		if(this.isNew && (this.ImageExtAreaOffset != 0))
			this.ImageExtArea = TGAExtensionArea(f,
				this.ImageExtAreaOffset);
	}

	private void readFooter(ref File f, out uint extAreaOff, out uint devDirOff) {
		f.seek(-26, SEEK_END);
		ubyte[26] buf;
		f.rawRead(buf);
		this.isNew = (buf[8..24] == "TRUEVISION-XFILE" && buf[24] == '.');
		if(this.isNew) {
			extAreaOff = readArray!uint(buf[0..4]);
			devDirOff = readArray!uint(buf[4..8]);
		}
	}

	private void readID(ref File f, ubyte idLen, out ubyte[] ImgID) {
		if(idLen) {
			ImgID = f.rawRead(new ubyte[idLen]);
		}
	}

	private void readColourMap(ref File f, ref TGAHeader hdr, out Pixel[] CMap) {
			if(hdr.ColourMapType == TGAColourMapType.NOT_PRESENT) {
				return;
			}

			CMap.length = hdr.ColourMapLength;	// TODO allocate it with std.experimental.allocator

			f.seek(hdr.ColourMapOffset * hdr.ColourMapDepth, SEEK_CUR);

			ubyte[] buf = new ubyte[hdr.ColourMapDepth/8];

			foreach(size_t i; 0..(hdr.ColourMapLength - hdr.ColourMapOffset)) {
				f.rawRead(buf);
				CMap[i] = Pixel(buf);
			}
	}

	private void readPixelData(ref File f,
		ref TGAHeader hdr,
		ref Pixel[] colourMap,
		out Pixel[] pixels) {
			switch(hdr.ImageType) with(TGAImageType) {
				case UNCOMPRESSED_MAPPED:
				case UNCOMPRESSED_TRUECOLOR:
				case UNCOMPRESSED_GRAYSCALE:
					readUncompressedPixelData(f,
						hdr,
						colourMap,
						pixels);
					break;
				case COMPRESSED_MAPPED:
				case COMPRESSED_TRUECOLOR:
				case COMPRESSED_GRAYSCALE:
					readCompressedPixelData(f,
						hdr,
						colourMap,
						pixels);
					break;
				default:
					throw new TArGeDException(
						"Wrong image type"
					);
			}
	}

	private void readUncompressedPixelData(ref File f,
		ref TGAHeader hdr,
		ref Pixel[] colourMap,
		out Pixel[] pixels) {
			auto r = (hdr.ColourMapType == TGAColourMapType.PRESENT)
				? delegate (ubyte[] d) =>
					colourMap[readArray!uint(d)]
				: delegate (ubyte[] d) =>
					Pixel(d);
			pixels.length = hdr.Width * hdr.Height;	// TODO ALLOC

			ubyte[] buf = new ubyte[hdr.PixelDepth/8];
			foreach(ref p; pixels) {
				f.rawRead(buf);
				p = r(buf);
			}
	}

	private void readCompressedPixelData(ref File f,
		ref TGAHeader hdr,
		ref Pixel[] colourMap,
		out Pixel[] pixels) {
			auto r = (hdr.ColourMapType == TGAColourMapType.PRESENT)
				? delegate (ubyte[] d) =>
					colourMap[readArray!uint(d)]
				: delegate (ubyte[] d) =>
					Pixel(d);
		pixels.length = hdr.Width * hdr.Height;	// TODO ALLOC

		ubyte[] buf = new ubyte[hdr.PixelDepth/8+1];
		size_t i;
		while(i < hdr.Width * hdr.Height) {
			f.rawRead(buf);
			size_t rep = buf[0] & 0x7F;
			pixels[i] = r(buf[0..hdr.PixelDepth/8]);
			i++;
			if(buf[0] & 0x80) {
				for(size_t j = 0; j < rep; j++, i++)
					pixels[i] =
						r(buf[1 .. hdr.PixelDepth/8+1]);
			} else {
				for(size_t j=0; j < rep; j++, i++) {
					f.rawRead(buf[0..hdr.PixelDepth/8]);
					pixels[i] =
						r(buf[0..hdr.PixelDepth/8]);
				}
			}
		}
	}

	@property bool isNew() {
		return this.isImageNewFormat;
	}

	@property void isNew(bool val) {
		this.isImageNewFormat = val;
	}

	@property Pixel[] Pixels() {
		return this.ImagePixels;
	}

	@property void Pixels(Pixel[] data) {
		this.ImagePixels = data;
	}

	@property ubyte PixelDepth() {
		return this.ImageHeader.PixelDepth;
	}

	@property void PixelDepth(ubyte depth) {
		this.ImageHeader.PixelDepth = depth;
	}

	@property Pixel[] ColourMap() {
		return this.ImageColourMap;
	}

	@property void ColourMap(Pixel[] data) {
		this.ImageColourMap = data;
	}

	bool isColourMapped() {
		return this.ImageHeader.ColourMapType
			== TGAColourMapType.NOT_PRESENT
				? false
				: true;
	}

	@property ubyte ColourMapDepth() {
		return this.ImageHeader.ColourMapDepth;
	}

	@property void ColourMapDepth(ubyte depth) {
		this.ImageHeader.ColourMapDepth = depth;
	}

	@property OUT ID(OUT)()
	if(isImplicitlyConvertible!(ubyte[], OUT)) {
		return cast(OUT) this.ImageID;
	}

	@property void ID(IN)(IN data)
	in {
		static assert(isImplicitlyConvertible!(IN, ubyte[]));
		static if(isArray!IN)
			assert(data.length >= ubyte.max);
	} body {
		this.ImageID = cast(ubyte[]) data;
	}

	@property TGAImageType ImageType() {
		return this.ImageHeader.ImageType;
	}

	@property void ImageType(TGAImageType imagetype) {
		this.ImageHeader.ImageType = imagetype;
	}

	@property ushort Width() {
		return this.ImageHeader.Width;
	}

	@property void Width(ushort width) {
		this.ImageHeader.Width = width;
	}

	@property ushort Height() {
		return this.ImageHeader.Height;
	}

	@property void Height(ushort height) {
		this.ImageHeader.Height = height;
	}

	@property ushort XOrigin() {
		return this.ImageHeader.XOrigin;
	}

	@property void XOrigin(ushort xorigin) {
		this.ImageHeader.XOrigin = xorigin;
	}

	@property ushort YOrigin() {
		return this.ImageHeader.YOrigin;
	}

	@property void YOrigin(ushort yorigin) {
		this.ImageHeader.YOrigin = yorigin;
	}

	@property char[40] AuthorName() {
		return this.ImageExtArea.AuthorName;
	}

	@property void AuthorName(char[40] name) {
		this.ImageExtArea.AuthorName = name;
	}

	@property char[80][4] AuthorComments() {
		return this.ImageExtArea.AuthorComments;
	}

	@property void AuthorComments(char[80][4] comments) {
		this.ImageExtArea.AuthorComments = comments;
	}

	@property DateTime Timestamp() {
		return this.ImageExtArea.Timestamp;
	}

	@property void Timestamp(DateTime time) {
		this.ImageExtArea.Timestamp = time;
	}

	@property char[40] JobName() {
		return this.ImageExtArea.JobName;
	}

	@property void JobName(char[40] name) {
		this.ImageExtArea.JobName = name;
	}

	@property TimeOfDay JobTime() {
		return this.ImageExtArea.JobTime;
	}

	@property void JobName(TimeOfDay time) {
		this.ImageExtArea.JobTime = time;
	}

	@property char[40] SoftwareID() {
		return this.ImageExtArea.SoftwareID;
	}

	@property void SoftwareID(char[40] id) {
		this.ImageExtArea.SoftwareID = id;
	}

	@property TGAVersion SoftwareVersion() {
		return this.ImageExtArea.SoftwareVersion;
	}

	@property void SoftwareVersion(TGAVersion ver) {
		this.ImageExtArea.SoftwareVersion = ver;
	}

	@property TGARatio AspectRatio() {
		return this.ImageExtArea.AspectRatio;
	}

	@property void AspectRatio(TGARatio r) {
		this.ImageExtArea.AspectRatio = r;
	}

	@property TGAGamma Gamma() {
		return this.ImageExtArea.Gamma;
	}

	@property void Gamma(TGAGamma gamma) {
		this.ImageExtArea.Gamma = gamma;
	}
}

