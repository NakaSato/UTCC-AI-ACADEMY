require "test_helper"

class AcademicPostPictureTest < ActiveSupport::TestCase
  test "accepts a bounded PNG with a matching signature" do
    upload = uploaded_picture

    assert_empty AcademicPostPictureValidator.errors_for(upload)
  ensure
    upload&.tempfile&.close!
  end

  test "rejects a mismatched content type and signature" do
    upload = uploaded_picture(content_type: "image/webp")

    assert_includes AcademicPostPictureValidator.errors_for(upload),
                    "The picture content does not match its declared type."
  ensure
    upload&.tempfile&.close!
  end

  private
    def uploaded_picture(content_type: "image/png")
      tempfile = Tempfile.new([ "academic-post-picture", ".png" ])
      tempfile.binmode
      tempfile.write(png_bytes)
      tempfile.rewind
      ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: "diagram.png",
        type: content_type
      )
    end

    def png_bytes
      "\x89PNG\r\n\x1A\n".b + ("\0" * 8) + [ 100, 100 ].pack("N2") + ("\0" * 32)
    end
end
