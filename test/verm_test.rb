require 'rubygems'
require 'minitest/autorun'
require 'verm/client'
require 'byebug' rescue nil

class TestVerm < Minitest::Test
  def setup
    @client = Verm::Client.new(ENV["VERM_TEST_HOSTNAME"] || "localhost")
  end

  def fixture_file_path(filename)
    File.join(File.dirname(__FILE__), 'fixtures', filename)
  end

  def test_stores_content_and_returns_location
    assert_equal "/test/files/F0/ZdYVIlyqOiCKtR_oQF_9y8G8_9qAWhR9Fw5hzK8UM.txt",
      @client.store("/test/files", "this is a test", "text/plain")

    assert_equal "/test/files/F0/ZdYVIlyqOiCKtR_oQF_9y8G8_9qAWhR9Fw5hzK8UM.txt",
      @client.store("/test/files/", "this is a test", "text/plain")

    assert_equal "/test/files/F0/ZdYVIlyqOiCKtR_oQF_9y8G8_9qAWhR9Fw5hzK8UM",
      @client.store("/test/files", "this is a test", "application/octet-stream")

    assert_equal "/test/files/SL/VHO4KGrhBRAAjinYUEdqilkOrS4JD6akWSeJb5Tra.txt",
      @client.store("/test/files", "this is a test\n", "text/plain")
  end

  def test_stores_files_and_returns_location
    File.open fixture_file_path("binary_file") do |f|
      assert_equal "/bins/IF/P8unS2JIuR6_UZI5pZ0lxWHhfvR2ocOcRAma_lEiA",
        @client.store("/bins/", f, "application/octet-stream")

      assert_equal "/bins/IF/P8unS2JIuR6_UZI5pZ0lxWHhfvR2ocOcRAma_lEiA.png",
        @client.store("/bins/", f, "image/png")
    end
  end

  def test_stores_compressed_files_and_returns_location_from_uncompressed_content
    File.open fixture_file_path("binary_file.gz") do |f|
      # note the hashes are the same here as the uncompressed file above
      assert_equal "/bins/IF/P8unS2JIuR6_UZI5pZ0lxWHhfvR2ocOcRAma_lEiA",
        @client.store("/bins/", f, "application/octet-stream", encoding: 'gzip')

      assert_equal "/bins/IF/P8unS2JIuR6_UZI5pZ0lxWHhfvR2ocOcRAma_lEiA.png",
        @client.store("/bins/", f, "image/png", encoding: 'gzip')
    end

    File.open fixture_file_path("large_compressed_csv_file.gz") do |f|
      assert_equal "/csvs/VP/YY9KXv6cc6XksLTHOQJywCHnzyQDCd7Xh7HHUO2hd.csv",
        @client.store("/csvs/", f, "text/csv", encoding: 'gzip')
    end
  end

  def test_loads_content_and_type
    content, type = "this is a test", "text/plain"
    assert_equal [content, type],
      @client.load(@client.store("/test/files_to_load", content, type))

    content, type = File.binread(fixture_file_path("binary_file")), "application/octet-stream"
    assert_equal [content, type],
      @client.load(@client.store("/test/files_to_load", content, type))
  end

  def test_loads_and_uncompresses_compressed_content_and_type
    compressed_content, type = File.binread(fixture_file_path("binary_file.gz")), "application/octet-stream"
    uncompressed_content = File.binread(fixture_file_path("binary_file"))

    assert_equal [uncompressed_content, type],
      @client.load(@client.store("/test/compressed", compressed_content, type, encoding: 'gzip'))
  end

  def test_optionally_doesnt_uncompress_compressed_content
    compressed_content, type = File.binread(fixture_file_path("binary_file.gz")), "application/octet-stream"

    assert_equal [compressed_content, type],
      @client.load(@client.store("/test/compressed", compressed_content, type, encoding: 'gzip'), 'Accept-Encoding' => 'gzip')
  end

  def test_marks_loaded_text_as_utf_8_by_default
    compressed_content, type = File.binread(fixture_file_path("large_compressed_csv_file.gz")), "text/csv"
    uncompressed_content = Zlib::GzipReader.new(StringIO.new(compressed_content)).read

    assert_equal [uncompressed_content, type],
      @client.load(@client.store("/test/compressed", compressed_content, type, encoding: 'gzip'))
  end

  def test_optionally_doesnt_mark_loaded_text_as_anything
    compressed_content, type = File.binread(fixture_file_path("large_compressed_csv_file.gz")), "text/csv"
    uncompressed_content = Zlib::GzipReader.new(StringIO.new(compressed_content)).read.force_encoding("ASCII-8BIT")

    assert_equal [uncompressed_content, type],
      @client.load(@client.store("/test/compressed", compressed_content, type, encoding: 'gzip'), force_text_encoding: nil)
  end

  def test_streams_content
    compressed_content, type = File.binread(fixture_file_path("large_compressed_csv_file.gz")), "application/octet-stream"
    uncompressed_content = Zlib::GzipReader.new(StringIO.new(compressed_content)).read.force_encoding("ASCII-8BIT")

    result = ""
    chunks = 0
    @client.stream(@client.store("/test/compressed", uncompressed_content, type)) do |chunk|
      result << chunk
      chunks += 1
    end
    assert_equal uncompressed_content, result
    assert chunks > 1, "should have been given the content in multiple chunks"
  end
end
