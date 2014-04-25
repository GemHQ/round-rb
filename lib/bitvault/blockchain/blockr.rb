require "http"
require "json"

require_relative "../bitcoin"

module BitVault
  module Blockchain

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

        # TODO: should we impose a limit on the number of addresses?
        string = addresses.join(",")
        url = "#{@base_url}/address/unspent/#{string}"

        response = @http.request "GET", url, :response => :object
        content = JSON.parse(response.body, :symbolize_names => true)

        if content[:status] != "success"
          raise "Blockr.io failure: #{content.to_json}"
        end

        outputs = []
        content[:data].each do |record|
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

      def bitcoins_to_satoshis(string)
        string.gsub(".", "").to_i
      end

    end

  end
end

