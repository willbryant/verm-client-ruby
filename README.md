Verm client library for Ruby
============================

Verm (https://github.com/willbryant/verm) is a WORM (write-once, read-many) file store to make it easy to reliably store and replicate files.  Clients talk to Verm over simple HTTP POST and GET calls.

This tiny client library adds one-line convenience methods for storing files in Verm and retrieving/streaming them back again.


Saving content
--------------

```ruby
mydata = "data to store"
VERM_CLIENT = Verm::Client.new("my-verm-server")
VERM_CLIENT.store("/important_gifs/january", mydata, "text/plain") # => String
```

The `store` call will return a path like `/important_gifs/january/ab/cdefgh.txt`, only longer (Verm makes the filename using an URL-safe base64 encoding of the SHA-256 of the content).


Saving files
------------

You don't need to read the whole file into memory before calling store, just pass the IO object in:

```ruby
VERM_CLIENT = Verm::Client.new("my-verm-server")

File.open("example.jpg", "rb") do |f|
  VERM_CLIENT.store("/important_gifs/january", f, "image/jpeg") # => String
end
```


Retrieving content
------------------

```ruby
VERM_CLIENT = Verm::Client.new("my-verm-server")

file, content_type = VERM_CLIENT.load("/important_gifs/january/ab/cdefgh.jpg")
```

This basically does the same thing as the built-in Net::HTTP get method (aside from timeouts, error handling, etc.):

```ruby
Net::HTTP.get('my-verm-server:3404', '/important_gifs/january/ab/cdefgh.jpg') # => String - the file content
```

So you really don't need a client library for this - but it's usually more convenient to configure the Verm server somewhere central, instead of sprinkling it through your application.

Verm stores all content without touching its character encoding, but Ruby 1.9+ treats all strings as having a specific character encoding.  Most applications use UTF-8 for all text, so by default, the `load` method will set the character encoding of `text/*` content returned by Verm to `UTF-8`.  You can override this or disable it entirely:

```ruby
file, content_type = VERM_CLIENT.load("/important_gifs/january/ab/cdefgh.csv", force_encoding: 'ISO-8859-1')
file, content_type = VERM_CLIENT.load("/important_gifs/january/ab/cdefgh.csv", force_encoding: nil)
```


Retrieving large content
------------------------

If the data is large, reading it all into memory as a string is inefficient.  Instead you can use `stream`, which will yield the file contents in chunks:

```ruby
VERM_CLIENT = Verm::Client.new("my-verm-server")

File.open("out.csv", "w") do |f|
  VERM_CLIENT.stream("/big_data/ab/cdefgh.csv") do |chunk|
    f.write chunk
  end
end
```

Because the chunks may not be broken on a character encoding boundary, the character encoding can't be set as for `load`, so they will still have the default `ASCII-8BIT` binary encoding.


File compression
----------------

Like HTTP and web browsers, Verm treats gzip compression as being a way of making transfers smaller and faster, not a separate file type.  So if you want to store gzipped files, you still get to say what content-type the actual file content has.

Saving files that are already gzip-compressed just requires one extra argument:

```ruby
File.open("acme_20150101.csv.gz", "rb") do |f|
  VERM_CLIENT.store("/third_party_files/acme/2015", f, "text/csv", encoding: "gzip")
end
```

It's important to note that Ruby's Net::HTTP client will automatically uncompress gzip transfer-encoding on responses - so when you use `load` or `store`, you'll get the uncompressed content back, not the gzip file.

You can suppress that behavior by passing `Accept-Encoding: gzip` as a header (Net::HTTP would accept gzip anyway, but setting this header has the side effect of disabling uncompression):

```ruby
file, content_type = VERM_CLIENT.load("/third_party_files/acme/2015/ab/cdefgh.csv", 'Accept-Encoding' => 'gzip')
```


Network stuff
-------------

Verm runs its HTTP server on port 3404 by default.  You can override this in the client configuration:

```ruby
VERM_CLIENT = Verm::Client.new("my-verm-server", port: 80)
```

Verm::Client defaults to a 15s timeout, which you can override:

```ruby
VERM_CLIENT = Verm::Client.new("my-verm-server", timeout: 60)
```

Like Net::HTTP, this timeout applies to individual network operations, not the whole method.
