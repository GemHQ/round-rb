# biteasy.rb
#
# Interface to BitEasy's Bitcoin API
#
# https://support.biteasy.com/kb
#
# Only supports v1 of the API (the only one at this time)
#
# TODO: if we pick this up again, finish adding in the 'use_curl'
# debugging/testing option so we can see if we're timing out when
# curl is not.

require "http"
require "json"

module BitVault
  module Blockchain

    class BitEasy
      include CoinOp::Encodings

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

        @use_curl = false
      end


      attr_accessor :max_per_request
      attr_accessor :per_page
      attr_accessor :use_curl


      # Return all unspent coins for each address in the list
      def unspent(addr_list)

        addr_count = addr_list.length

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
          outputs << CoinOp::Bit::Output.new(
            :transaction_hex => transaction_hex,
            :index => index,
            :value => value, # Seems to already be in Satoshis
            :script => script_hex,
            :address => address,
          )
        end

        outputs.sort_by {|output| -output.value }
      end


      def transaction(transactions)

        if not transactions.is_a? Array
          transactions = [transactions]
        end

        # Sadly, we can only request a single transaction at a time
        # from BitEasy
        results = []
        transactions.each do |tx|
          results.concat (request "transactions/#{tx}")
        end

        results
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

          page_url = "#{url}&page=#{page}&per_page=#@per_page"

          page_data = raw_request page_url

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


      # Manages a single raw request with error handling for batch_request
      def raw_request url

        if @use_curl
          response = `/usr/bin/curl -H`
        else
          response = @http.request "GET", url, :response => :object
        end

        begin
          content = JSON.parse(response.body, :symbolize_names => true)
        rescue JSON::ParserError => e
          raise "BitEasy returned invalid JSON: #{e}"
        end

        if content[:status] != 200
          raise "BitEasy.com failure: #{content.to_json}"
        end

        # TODO Check pagination data and handle multiple pages

        data = content[:data]
      end

    end

  end

end

