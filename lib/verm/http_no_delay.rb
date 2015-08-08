require 'net/http'

# This class can be used as a workaround for Net::HTTP's lack of TCP_CORK/TCP_NOPUSH in sending
# requests.  When using a Linux client and a Linux server we observe awful latency POSTing files on
# reused HTTP connections because Post class writes one block of data for the header and separate
# block(s) for the body.  If the body is not sufficiently large to fill another packet itself, the
# Nagle algorithm will have Linux (by default) wait for the ACK from the first packet to be received
# back; unfortunately, this won't be sent immediately because of the Delayed ACK algorithm.  As a
# result we typically observe 40ms of extra latency when POSTing small files.  This class disables
# the Nagle algorithm to work around that.  It's not an ideal fix because we would rather combine
# the write for the header with the write for the first N bytes of the body, but it should give
# performance better than the standard Ruby implementation in all cases because Nagle is of no
# benefit when queuing large blocks only to the OS (as both the streaming and non-streaming
# variants of the body write calls will do), and the way that Ruby is writing the header separately
# to the body means there will always be at least two packets anyway.
class Net::HTTPNoDelay < Net::HTTP
  def on_connect()
    @socket.io.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
  end
end
