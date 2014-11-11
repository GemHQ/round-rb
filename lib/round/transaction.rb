class Round::Transaction < Round::Base
  def_delegators :@resource, :data, :type
end