class Round::Address < Round::Base
  def_delegators :@resource, :path, :string  
end