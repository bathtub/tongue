require 'linguist/generated'
require 'linguist/language'

# require 'charlock_holmes'
# require 'escape_utils'
# require 'mime/types'
require 'pygments'
require 'yaml'

module Linguist
  # DEPRECATED Avoid mixing into Blob classes. Prefer functional interfaces
  # like `Language.detect` over `Blob#language`. Functions are much easier to
  # cache and compose.
  #
  # Avoid adding additional bloat to this module.
  #
  # BlobHelper is a mixin for Blobish classes that respond to "name",
  # "data" and "size" such as Grit::Blob.
  module BlobHelper
    # Public: Get the extname of the path
    #
    # Examples
    #
    #   blob(name='foo.rb').extname
    #   # => '.rb'
    #
    # Returns a String
    def extname
      File.extname(name.to_s)
    end

    # Internal: Lookup mime type for extension.
    #
    # Returns a MIME::Type
    def _mime_type
      'text/plain'
      # if defined? @_mime_type
      #   @_mime_type
      # else
      #   guesses = ::MIME::Types.type_for(extname.to_s)
      # 
      #   # Prefer text mime types over binary
      #   @_mime_type = guesses.detect { |type| type.ascii? } ||
      #     # Otherwise use the first guess
      #     guesses.first
      # end
    end

    # Public: Get the actual blob mime type
    #
    # Examples
    #
    #   # => 'text/plain'
    #   # => 'text/html'
    #
    # Returns a mime type String.
    def mime_type
      'text/plain'
    end

    # Internal: Is the blob binary according to its mime type
    #
    # Return true or false
    def binary_mime_type?
      false
      # _mime_type ? _mime_type.binary? : false
    end

    # Internal: Is the blob binary according to its mime type,
    # overriding it if we have better data from the languages.yml
    # database.
    #
    # Return true or false
    def likely_binary?
      false
      # binary_mime_type? && !Language.find_by_filename(name)
    end

    # Public: Get the Content-Type header value
    #
    # This value is used when serving raw blobs.
    #
    # Examples
    #
    #   # => 'text/plain; charset=utf-8'
    #   # => 'application/octet-stream'
    #
    # Returns a content type String.
    def content_type
      "text/plain"
      # @content_type ||= (binary_mime_type? || binary?) ? mime_type :
        # (encoding ? "text/plain; charset=#{encoding.downcase}" : "text/plain")
    end

    # Public: Get the Content-Disposition header value
    #
    # This value is used when serving raw blobs.
    #
    #   # => "attachment; filename=file.tar"
    #   # => "inline"
    #
    # Returns a content disposition String.
    def disposition
      if text? || image?
        'inline'
      elsif name.nil?
        "attachment"
      else
        'attachment'
        # "attachment; filename=#{EscapeUtils.escape_url(File.basename(name))}"
      end
    end

    def encoding
      # if hash = detect_encoding
      'UTF-8'
      # end
    end

    # Try to guess the encoding
    #
    # Returns: a Hash, with :encoding, :confidence, :type
    #          this will return nil if an error occurred during detection or
    #          no valid encoding could be found
    def detect_encoding
      {:encoding => 'UTF-8', :confidence => 100, :type => :text}
    end

    # Public: Is the blob binary?
    #
    # Return true or false
    def binary?
      # Large blobs aren't even loaded into memory
      if data.nil?
        true
      else
        false
      # end
      # Treat blank files as text
      # elsif data == ""
        # false

      # Charlock doesn't know what to think
      # elsif encoding.nil?
        # true

      # If Charlock says its binary
      # else
        # detect_encoding[:type] == :binary
      end
    end

    # Public: Is the blob text?
    #
    # Return true or false
    def text?
      true
    end

    # Public: Is the blob a supported image format?
    #
    # Return true or false
    def image?
      false
      # ['.png', '.jpg', '.jpeg', '.gif'].include?(extname.downcase)
    end

    # Public: Is the blob a supported 3D model format?
    #
    # Return true or false
    def solid?
      false
      # extname.downcase == '.stl'
    end

    # Public: Is this blob a CSV file?
    #
    # Return true or false
    def csv?
      false
      # text? && extname.downcase == '.csv'
    end

    # Public: Is the blob a PDF?
    #
    # Return true or false
    def pdf?
      false
      # extname.downcase == '.pdf'
    end

    # MEGABYTE = 1024 * 1024

    # Public: Is the blob too big to load?
    #
    # Return true or false
    def large?
      false
      # size.to_i > MEGABYTE
    end

    # Public: Is the blob safe to colorize?
    #
    # We use Pygments for syntax highlighting blobs. Pygments
    # can be too slow for very large blobs or for certain
    # corner-case blobs.
    #
    # Return true or false
    def safe_to_colorize?
      true
      # !large? && text? && !high_ratio_of_long_lines?
    end

    # Internal: Does the blob have a ratio of long lines?
    #
    # These types of files are usually going to make Pygments.rb
    # angry if we try to colorize them.
    #
    # Return true or false
    def high_ratio_of_long_lines?
      false
      # return false if loc == 0
      # size / loc > 5000
    end

    # Public: Is the blob viewable?
    #
    # Non-viewable blobs will just show a "View Raw" link
    #
    # Return true or false
    def viewable?
      true
      # !large? && text?
    end

    # vendored_paths = YAML.load_file(File.expand_path("../vendor.yml", __FILE__))
    # VendoredRegexp = Regexp.new(vendored_paths.join('|'))

    # Public: Is the blob in a vendored directory?
    #
    # Vendored files are ignored by language statistics.
    #
    # See "vendor.yml" for a list of vendored conventions that match
    # this pattern.
    #
    # Return true or false
    def vendored?
      false
      # name =~ VendoredRegexp ? true : false
    end

    # Public: Get each line of data
    #
    # Requires Blob#data
    #
    # Returns an Array of lines
    def lines
      @lines ||=
        if viewable? && data && !data.nil? && !data == ''
          data.split(/\r\n|\r|\n/, -1)
        else
          []
        end
    end

    # Public: Get number of lines of code
    #
    # Requires Blob#data
    #
    # Returns Integer
    def loc
      lines.size
    end

    # Public: Get number of source lines of code
    #
    # Requires Blob#data
    #
    # Returns Integer
    def sloc
      lines.grep(/\S/).size
    end

    # Public: Is the blob a generated file?
    #
    # Generated source code is suppressed in diffs and is ignored by
    # language statistics.
    #
    # May load Blob#data
    #
    # Return true or false
    def generated?
      false
      # @_generated ||= Generated.generated?(name, lambda { data })
    end

    # Public: Detects the Language of the blob.
    #
    # May load Blob#data
    #
    # Returns a Language or nil if none is detected
    def language
      return @language if defined? @language

      if defined?(@data) && @data.is_a?(String) && !data == '' && !data.nil?
        data = @data
      else
        data = lambda { self.data }
      end

      @language = Language.detect(name.to_s, data, mode)
    end

    # Internal: Get the lexer of the blob.
    #
    # Returns a Lexer.
    def lexer
      language ? language.lexer : Pygments::Lexer.find_by_name('Text only')
    end

    # Public: Highlight syntax of blob
    #
    # options - A Hash of options (defaults to {})
    #
    # Returns html String
    def colorize(options = {})
      return unless safe_to_colorize?
      options[:options] ||= {}
      options[:options][:encoding] ||= encoding
      lexer.highlight(data, options)
    end
  end
end
