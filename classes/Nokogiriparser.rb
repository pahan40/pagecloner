class Nokogiriparser
  attr_accessor :html, :nokobody

  def initialize(html)
    @html = html
    @nokobody = Nokogiri::HTML(html.to_s)
  end
end
