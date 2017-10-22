class Mybrowser
  attr_accessor :url, :browser, :headless, :deepscrubbing
  def initialize(url,deepscrubbing=false)
    @url = url
    @headless = Headless.new
    @headless.start
    @browser = Watir::Browser.start @url
    @deepscrubbing = deepscrubbing
  end

  def nokogiribody
    doc = Nokogiri::HTML(@browser.html)
    ids = []
    if @deepscrubbing
      doc.traverse do |node|
        if node["id"]
          ids << node["id"]
        end
      end
      ids.each do |id|
        @browser.elements(:id => id.to_s).each do |elem|
          elem.wd.location_once_scrolled_into_view
          sleep 1
        end
      end
    end
    @browser.scroll.to :center
    sleep 1
    @browser.scroll.to :bottom
    sleep 1
    @browser.scroll.to :top
    return doc
  end

  def destroy
    @headless.destroy
  end

end