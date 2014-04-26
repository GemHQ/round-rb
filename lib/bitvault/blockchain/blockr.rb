require "http"
require "json"

require_relative "../bitcoin"

module BitVault
  module Blockchain

    # Blockr.io API documentation:  http://blockr.io/documentation/api
    class Blockr
      include BitVault::Encodings

      def initialize(env="test")
        subdomain = (env == "test") ? "tbtc" : "btc"
        @base_url = "http://#{subdomain}.blockr.io/api/v1"
        @http = HTTP.with_headers(
          "User-Agent" => "bv-blockchain-worker v0.1.0",
          "Accept" => "application/json"
        )
      end

      def unspent(addresses, confirmation_level=6)

        data = get_response_data(:address, :unspent, addresses)

        outputs = []
        data.each do |record|
          record[:unspent].each do |output|
            address = record[:address]

            if output[:confirmations] >= confirmation_level
              transaction_hex, index, value, script_hex =
                output.values_at :tx, :index, :amount, :script

              outputs << BitVault::Bitcoin::Output.new(
                :transaction_hex => transaction_hex,
                :index => index,
                :value => bitcoins_to_satoshis(value),
                :script => {:hex => script_hex},
                :address => address
              )

            end

          end
        end

        outputs.sort_by {|output| -output.value }
      end


      def balance(addresses)
        data = get_response_data(:address, :balance, addresses)
        balances = {}
        data.each do |record|
          balances[record[:address]] = record[:balance]
        end

        balances
      end


      def transactions(tx_ids)
        data = get_response_data(:tx, :info, tx_ids)

        data
      end


      def address_info(addresses, confirmations="")
        # Useful for testing transactions()
        get_response_data("address", "info", addresses, confirmations)
      end



      # Helper methods

      def bitcoins_to_satoshis(string)
        string.gsub(".", "").to_i
      end


      def get_response_data(from_type, to_type, args, *query_parameters)
        # Queries the Blockr Bitcoin from_type => to_type API with
        # list, returning the results or throwing an exception on
        # failure.

        # Permit calling with either an array or a scalar
        if args.respond_to? :join
          args = args.join(",")
        end
        url = "#{@base_url}/#{from_type}/#{to_type}/#{args}"

        # Permit query parameters such as "confirmations", but allow
        # "" for no parameters
        if query_parameters.length > 0 and query_parameters[0].length > 0
          url << "?#{query_parameters.join ","}"
        end

        response = @http.request "GET", url, :response => :object
        # FIXME:  rescue any JSON parsing exception and raise an
        # exception explaining that it's blockr's fault.
        # Doesn't the "raise" below do this now? -- DLL
        content = JSON.parse(response.body, :symbolize_names => true)

        if content[:status] != "success"
          raise "Blockr.io failure: #{content.to_json}"
        end

        data = content[:data]

        # Make the return type consistent to simplify client code
        if not data.kind_of?(Array)
          data = [data]
        end

        data
      end

    end

  end
end

