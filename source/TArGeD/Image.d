module TArGeD.Image;

import TArGeD.Defines;
import TArGeD.Old.Util;
import std.stdio;

class Image {
	private {
		TGAHeader ImageHeader;
		ubyte[] ImageID;
		Pixel[] ImageColorMap;
		Pixel[] ImagePixels;
		uint ImageExtAreaOffset;
		uint ImageDevDirOffset;
		TGAExtensionArea ImageExtArea;
		uint[] ImageScanLineTable;

		bool isImageNewFormat;
	}

	@property bool isNew() {
		return this.isImageNewFormat;
	}

	@property void isNew(bool val) {
		this.isImageNewFormat = val;
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
		this.readColorMap(f,
			this.ImageHeader,
			this.ImageColorMap);
		this.readPixelData(f,
			this.ImageHeader,
			this.ImageColorMap,
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

	private void readColorMap(ref File f, ref TGAHeader hdr, out Pixel[] CMap) {
			if(hdr.CMapType == ColorMapType.NOT_PRESENT) {
				return;
			}

			CMap.length = hdr.CMapLength;	// TODO allocate it with std.experimental.allocator

			f.seek(hdr.CMapOffset * hdr.CMapDepth, SEEK_CUR);

			ubyte[] buf = new ubyte[hdr.CMapDepth/8];

			foreach(size_t i; 0..(hdr.CMapLength - hdr.CMapOffset)) {
				f.rawRead(buf);
				CMap[i] = Pixel(buf);
			}
	}

	private void readPixelData(ref File f,
		ref TGAHeader hdr,
		ref Pixel[] colorMap,
		out Pixel[] pixels) {
			switch(hdr.IType) with(ImageType) {
				case UNCOMPRESSED_MAPPED:
				case UNCOMPRESSED_TRUECOLOR:
				case UNCOMPRESSED_GRAYSCALE:
					readUncompressedPixelData(f,
						hdr,
						colorMap,
						pixels);
					break;
				case COMPRESSED_MAPPED:
				case COMPRESSED_TRUECOLOR:
				case COMPRESSED_GRAYSCALE:
					readCompressedPixelData(f,
						hdr,
						colorMap,
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
		ref Pixel[] colorMap,
		out Pixel[] pixels) {
			auto r = (hdr.CMapType == ColorMapType.PRESENT)
				? delegate (ubyte[] d) =>
					colorMap[readArray!uint(d)]
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
		ref Pixel[] colorMap,
		out Pixel[] pixels) {
			auto r = (hdr.CMapType == ColorMapType.PRESENT)
				? delegate (ubyte[] d) =>
					colorMap[readArray!uint(d)]
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
}

