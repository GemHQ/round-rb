module Round::Helpers
  def extract_params(header)
    header.scan(/(\S*)\=\"(\S*)\"/).inject({}) {|memo, match| 
      memo[match[0].to_sym] = match[1]
      memo
    }
  end
end