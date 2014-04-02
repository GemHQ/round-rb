
module BitVault::Bitcoin

  module Encodings
    extend self

    def hex(blob)
      blob.unpack("H*")[0]
    end

    def decode_hex(string)
      [string].pack("H*")
    end

    def base58(blob)
      Bitcoin.encode_base58(self.hex(blob))
    end

    def decode_base58(string)
      self.decode_hex(Bitcoin.decode_base58(string))
    end
  end

end

