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
        @max_per_request = 10

        # This is about the results returned per page
        # Can never be more than 40
        @per_page = 40

        @http = HTTP.with_headers(
          "User-Agent" => "bv-blockchain-worker v0.1.0",
          "Accept" => "application/json"
        )
      end


      attr_accessor :max_per_request
      attr_accessor :per_page


      # Return all unspent coins for each address in the list
      def unspent(addr_list)

        addr_count = addr_list.length
puts "Total addresses in request: #{addr_count}"
puts "Max per request: #@max_per_request"
puts "Max results per page: #@per_page"

        if addr_count == 0
          raise "BitEasy error: no addresses requested"
        end

        results = request "unspent-outputs", addr_list

        # Construct Output objects from the raw JSON
        outputs = []
        results.each do |result|
          transaction_hex, index, value, script_hex, address =
            result.values_at(
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

        outputs.sort_by {|output| -output.value }
      end


      def transaction(tx_id)

        request "transactions/#{tx_id}"
      end


      # Helper methods

      def bitcoins_to_satoshis(string)
        string.gsub(".", "").to_i
      end

      def float_to_satoshis(float)
        (float * 100_000_000).to_i
      end


      # Queries the BitEasy Bitcoin API endpoint given by path with the list of
      # arguments in args, giving them the name in arg_name.  args may be nil,
      # an empty array, or the empty string for requests that don't take
      # parameters.
      def request(path, args=[], arg_name="address[]")

        # OK for args to be nil
        args = [] if not args

        # Permit calling with either an array or a scalar
        unless args.is_a? Array
          args = [args]
        end

        root_url = "#@base_url/#@net/#@version/#{path}?"

        # Batch loop--we never ask for more than @max_per_request at a time
        outputs = []
        if args.length == 0
          outputs = batch_request root_url
        else
          args.each_slice(@max_per_request) do |arg_slice|

            arg_string = arg_slice.map {|arg| "#{arg_name}=#{arg}"}.join("&")
            request_url = "#{root_url}#{arg_string}"

            outputs.concat batch_request request_url
          end

        end

        outputs
      end


      # Request a single batch--mainly handles paging for request()
      def batch_request url

        page = 1
        outputs = []
        loop do
puts
puts "Page: #{page}"
          page_url = "#{url}&page=#{page}&per_page=#@per_page"
puts "Page URL: #{page_url}"

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
puts "Page data:"
puts JSON.pretty_generate page_data

          page_outputs = page_data[:outputs]
          outputs.concat page_outputs

          pagination = page_data[:pagination]
          if pagination
            page = pagination[:next_page]
          else
            # Requests for single items don't have pagination, so we're done
            page = nil
          end
          break unless page
        end

        outputs
      end

    end

  end

end

