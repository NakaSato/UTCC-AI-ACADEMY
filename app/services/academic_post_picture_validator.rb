class AcademicPostPictureValidator
  ALLOWED_TYPES = {
    "image/jpeg" => "jpeg",
    "image/png" => "png",
    "image/webp" => "webp"
  }.freeze
  MAX_BYTES = 5.megabytes
  MAX_DIMENSION = 6_000

  def self.errors_for(upload)
    new(upload).errors
  end

  def initialize(upload)
    @upload = upload
  end

  def errors
    return [ "A picture is required." ] unless upload&.tempfile
    return [ "The picture format is not supported." ] unless ALLOWED_TYPES.key?(upload.content_type)
    return [ "The picture is too large." ] if upload.tempfile.size > MAX_BYTES
    return [ "The picture content does not match its declared type." ] unless signature_matches?

    width, height = dimensions
    return [ "The picture dimensions could not be read." ] unless width && height
    return [ "The picture dimensions are too large." ] if width > MAX_DIMENSION || height > MAX_DIMENSION

    []
  ensure
    upload&.tempfile&.rewind
  end

  private
    attr_reader :upload

    def bytes
      @bytes ||= File.binread(upload.tempfile.path)
    end

    def signature_matches?
      case upload.content_type
      when "image/jpeg"
        bytes.start_with?("\xFF\xD8\xFF".b)
      when "image/png"
        bytes.start_with?("\x89PNG\r\n\x1A\n".b)
      when "image/webp"
        bytes.start_with?("RIFF".b) && bytes.byteslice(8, 4) == "WEBP"
      end
    end

    def dimensions
      case upload.content_type
      when "image/png"
        [ bytes.byteslice(16, 4)&.unpack1("N"), bytes.byteslice(20, 4)&.unpack1("N") ]
      when "image/webp"
        webp_dimensions
      when "image/jpeg"
        jpeg_dimensions
      end
    end

    def webp_dimensions
      return unless bytes.byteslice(12, 4) == "VP8X"

      width = 1 + unpack_little_endian(bytes.byteslice(24, 3))
      height = 1 + unpack_little_endian(bytes.byteslice(27, 3))
      [ width, height ]
    end

    def jpeg_dimensions
      offset = 2
      while offset + 9 < bytes.bytesize
        offset += 1 while bytes.getbyte(offset) == 0xFF
        marker = bytes.getbyte(offset)
        offset += 1
        return unless marker && marker != 0xD8 && marker != 0xD9

        length = bytes.byteslice(offset, 2)&.unpack1("n")
        return unless length && length >= 2

        if (0xC0..0xC3).cover?(marker) || (0xC5..0xC7).cover?(marker) ||
           (0xC9..0xCB).cover?(marker) || (0xCD..0xCF).cover?(marker)
          return [ bytes.byteslice(offset + 3, 2).unpack1("n"),
                   bytes.byteslice(offset + 5, 2).unpack1("n") ]
        end
        offset += length
      end
    end

    def unpack_little_endian(value)
      value.bytes.each_with_index.sum { |byte, index| byte << (index * 8) }
    end
end
