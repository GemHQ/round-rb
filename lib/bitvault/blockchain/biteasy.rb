# biteasy.rb
#
# Interface to BitEasy's Bitcoin API
#
# https://support.biteasy.com/kb
#
# Currently only supports v1 of the API
#
# Need to implement:
# Unspent outputs for multiple addresses
# Retrieve single transaction
# Summaries for multiple addresses

require "http"
require "json"

require_relative "../bitcoin"

module BitVault
  module Blockchain

    class BitEasy
      include BitVault::Encodings

      def initialize(net=:test)
        @net = (net.to_sym == :test) ? "testnet" : "blockchain"
        @version = "v1"
        @base_url = "https://api.biteasy.com"

        # TODO: consider raising this, though the API default of 10 may
        # be a hint that they prefer many small requests to fewer larger
        # ones. The code works for any positive value.
        @per_page = 20

        @http = HTTP.with_headers(
          "User-Agent" => "bv-blockchain-worker v0.1.0",
          "Accept" => "application/json"
        )
      end


      def unspent(addr_list)
        # Permit calling with either an array or a scalar
        unless addr_list.is_a? Array
          addr_list = [addr_list]
        end

        addr_count = addr_list.length

        if addr_count == 0
          raise "BitEasy failure: no addresses requested"
        end

        addr_str = addr_list.map { |address| "address[]=#{address}" }.join("&")
        params = "#{addr_str}&per_page=#@per_page"

        request_url = "#@base_url/#@net/#@version/unspent-outputs?#{params}"

        page = 1
        outputs = []
        loop do
puts "Page: #{page}"
          page_url = "#{request_url}&page=#{page}"

          response = @http.request "GET", page_url, :response => :object

          begin
            page_content = JSON.parse(response.body, :symbolize_names => true)
          rescue JSON::ParserError => e
            raise "BitEasy returned invalid JSON: #{e}"
          end

          if page_content[:status] != 200
            raise "BitEasy.com failure: #{page_content.to_json}"
          end

          # TODO Check pagination data and handle multiple pages
          page_data = page_content[:data]
          page_outputs = page_data[:outputs]

          page_outputs.each do |output|
            transaction_hex, index, value, script_hex, address =
              output.values_at(
                :transaction_hash,
                :transaction_index,
                :value,
                :script_pub_key,
                :to_address
            )
            outputs << BitVault::Bitcoin::Output.new(
              :transaction_hex => transaction_hex,
              :index => index,
              :value => value, # Seems to already be in Satoshis
              :script => script_hex,
              :address => address,
            )
          end

          page = page_data[:pagination][:next_page]
          break unless page
        end

        outputs.sort_by {|output| -output.value }
      end


      def transaction(tx_id)

        url = "#@base_url/#@net/#@version/transactions/#{tx_id}"

        response = @http.request "GET", url, :response => :object
        # FIXME:  rescue any JSON parsing exception and raise an
        # exception explaining that it's BitEasy's fault.
        content = JSON.parse(response.body, :symbolize_names => true)

        if content[:status] != 200
          raise "BitEasy.com failure: #{content.to_json}"
        end

        data = content[:data]
      end


      # Helper methods

      def bitcoins_to_satoshis(string)
        string.gsub(".", "").to_i
      end

      def float_to_satoshis(float)
        (float * 100_000_000).to_i
      end

    end

  end

end

