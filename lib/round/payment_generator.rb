module Round
  class PaymentGenerator < Round::Base

    def unsigned(payees, confirmations = 6)
      raise 'Must have list of payees' unless payees

      payment_resource = @resource.create(
        { confirmations: confirmations }.merge(self.outputs_from_payees(payees))
      )
      Round::Payment.new(resource: payment_resource)
    end

    def outputs_from_payees(payees)
      raise ArgumentError, 'Payees must be an array' unless payees.is_a?(Array)
      outputs = payees.map do |payee|
        raise 'Bad output, no amount' unless payee[:amount]
        raise 'Bad output, no address' unless payee[:address]
        {
          amount: payee[:amount],
          payee: { address: payee[:address] }
        }
      end
      { outputs: outputs }
    end

  end
end
