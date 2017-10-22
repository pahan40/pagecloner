class Clonepage
  attr_accessor :url, :host, :path, :scheme
  def initialize(url)
    @url = url
    ur = URI.parse(url)
    @host = ur.host
    @scheme = ur.scheme
    @path = ur.path
  end
end