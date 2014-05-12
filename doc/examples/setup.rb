require "pp"

project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
$:.unshift "#{project_root}/lib"

## 
#$LOAD_PATH.unshift "#{project_root}/../bitcoin-ruby/lib"
#$LOAD_PATH.unshift "#{project_root}/../patchboard-rb/lib"


require "bitvault"
require "#{project_root}/test/helpers/mockchain"
require "#{project_root}/test/helpers/bitcoin"
require "#{project_root}/test/helpers/testnet_assets"

