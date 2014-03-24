module CSON
  module_function

  def stringify(object, indent="", parent=nil)
    case object
    when Hash
      if object.size == 0
        " {}"
      else
        properties = object.map do |key, value|
          property(key.to_s, stringify(value, indent + "  "))
        end
        properties = properties.join("\n#{indent}")
        if parent == "array"
          "{\n#{indent}#{properties}\n#{indent.slice(0..-3)}}"
        else
          "\n#{indent}#{properties}\n#{indent}"
        end
      end
    when String
      " " + object.dump
    when Regexp
      object.inspect
    when Array
      if object.size == 0
        " []"
      else
        items = object.map do |item|
          stringify(item, indent + "  ", "array")
        end
        items = items.join("\n#{indent}")
        " [\n#{indent}#{items}\n#{indent.slice(0..-3)}]"
      end
    else
      " " + object.to_s
    end
  end

end

def property(key, value)
  if key =~ /^[\w_]+$/
    "#{key}:#{value}"
  else
    %Q/"#{key}": #{value}/
  end
end

