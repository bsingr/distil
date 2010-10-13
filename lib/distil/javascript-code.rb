class JavascriptCode < String
  def to_json(*options)
    self
  end
end

module Kernel
  # A convenience factory method
  def JavascriptCode(str)
    JavascriptCode.new(str)
  end
end
