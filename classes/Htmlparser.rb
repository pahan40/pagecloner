class Htmlparser
  attr_reader :data, :minifyoptions
  def initialize(data)
    @data = data
    @minifyoptions = {
        collapseInlineTagWhitespace: true,
        collapseWhitespace: true,
        removeComments: true,
        removeTagWhitespace: true
    }
  end

  def find_inline_images
    images = []
    @data.traverse do |node|
      node.keys.each do |attr|
        if attr == 'style' && node["#{attr}"].to_s.include?("url")
          img = found_url_in_style_attribute(node, attr)
          images.push img
        end
      end
    end
    images
  end

  def find_images_in_link_href
    images = []
    @data.css("a").each do |pagelink|
      if pagelink["href"].to_s =~ /.*\.jpg|png.*/
        img = found_image_url_in_href(pagelink)
        images.push img
      end
    end
    images
  end

  def find_images_img_tag
    images = []
    @data.css("img").each do |image|
      if !image["src"].to_s.empty?
        img = found_image_src(image)
        images.push img
      end
    end
    images
  end

  def get_css_style_inside_html
    styles = @data.css("style")
    styles
  end

  def find_images_inside_css_styles_inside_html_page
    images = []
    styles = get_css_style_inside_html
    styles.each do |style|
      parser = CssParser::Parser.new
      parser.load_string! style.text
      parser.each_selector do |selector, declarations, specificity|
        if declarations.include?("url")
          image = prepare_img_url_from_css(declarations)
          images.push(image)
        end
      end
    end
    images.uniq
  end

  def find_image_inside_css(cssdata)
    images = []
    parser = CssParser::Parser.new
    parser.load_string! cssdata
    parser.each_selector do |selector, declarations, specificity|
      if declarations.include?("url")
        image = prepare_img_url_from_css(declarations)
        images.push image
      end
    end
    images.uniq
  end

  def replace_images_img_tag(imgarray)
    @data.css("img").each do |image|
      if !image["src"].to_s.empty?
        imgarray.each do |img|
          newstr = image["src"].to_s.gsub!(img[:url].to_s, img[:uploaded_url])
          image["src"] = newstr.to_s.gsub('"','') if !newstr.nil?
        end
      end
    end
  end

  def replace_inline_images_with_valid_url(imgarray)
    @data.traverse do |node|
      node.keys.each do |attr|
        if attr == 'style'
          if node["#{attr}"].to_s.include?("url")
            imgarray.each do |img|
              str = node["#{attr}"]
              newstr = str.to_s.gsub!(img[:url].to_s, img[:uploaded_url])
              node["#{attr}"] = newstr.gsub('"','') if !newstr.nil?
            end
          end
        end
      end
    end
  end

  def replace_images_url_in_link_href(imgarray)
    @data.css("a").each do |pagelink|
      if pagelink["href"].to_s =~ /.*\.jpg|png.*/
        imgarray.each do |img|
          newstr = pagelink["href"].to_s.gsub!(img[:url].to_s, img[:uploaded_url])
          pagelink["href"] = newstr.gsub('"','') if !newstr.nil?
        end
      end
    end
  end

  def replace_inline_css_styles_images(imgarray)
    styles = get_css_style_inside_html
    allstyles = styles.text.to_s
    imgarray.each do |img|
      allstyles = allstyles.to_s.gsub(img[:url].to_s, img[:uploaded_url])
    end
    allstyles
  end

  def found_image_src(img)
    matched_url = img["src"]
    imgname = get_image_name(matched_url)
    return {name: imgname, url: matched_url}
  end

  def found_image_url_in_href(pagelink)
    matched_url = pagelink["href"]
    imgname = get_image_name(matched_url)
    return {name: imgname, url: matched_url}
  end

  def found_css_link(link)
    matched_url = link
    css_name = get_image_name(matched_url)
    return {name: css_name, url: matched_url}
  end

  def found_url_in_style_attribute(node, attr)
    matched_url = node["#{attr}"].match(/url\(.*\)/)
    cleared_url = clear_url(matched_url)
    imgname = get_image_name(cleared_url)
    return {name: imgname, url: cleared_url}
  end

  def clear_url(url)
    url.to_s.match(/\(.*?\)/).to_s.gsub("(",'').gsub(")",'').gsub(/\"/,'')
  end

  def get_image_name(url)
    url.split("/").last.gsub(/\?.*/i, '')
  end

  def prepare_img_url_from_css(declaration)
    urlstr = declaration.match(/url\(.*?\)/)
    imgurl = urlstr.to_s.gsub("url", '').gsub("'", '').gsub('"', '').gsub("(", '').gsub(")",'')
    imgname = get_image_name(imgurl)
    {name: imgname, url: imgurl}
  end

  def get_body_styles
    body = @data.css("body")[0]
    if !body.nil?
      bodystyles = body.styles.to_s
    else
      bodystyles = ''
    end
    bodystyles
  end

  def get_linkhref_styles
    cssfiles = []
    linkhref = @data.css("link")
    linkhref.each do |file|
      cssfiles.push file if file["type"].to_s == 'text/css' || file["type"].to_s == ''
    end
    cssfiles
  end

  def clear_html
    @data.css("link").remove()
    @data.css("style").remove()
    @data.css("script").remove()
  end
  def clear_wrong_tags
    @data.xpath("//*").each do |t|
      if t.name.to_s.include?(".") || t.name.to_s.include?(":")
        t.remove()
      end
    end
  end
  def clear_wrong_attributes
    @data.traverse do |node|
      node.keys.each do |attribute|
        if attribute.to_s.include?(".") || attribute.to_s.include?(":")
          node.delete attribute
        end
      end
    end
  end
  def clear_onclick_attr
    @data.traverse do |node|
      node.keys.each do |attribute|
        if attribute.to_s == 'onClick' || attribute.to_s == 'onclick'
          node.delete attribute
        end
      end
    end

  end

  def clear_wrong_attributes_and_tags
    clear_wrong_tags
    clear_wrong_attributes
    clear_onclick_attr
  end

  def minify_html
    HtmlMinifier.minify(@data.to_xhtml.to_s.encode("UTF-8", :undef => :replace, :invalid => :replace, :replace => ""), @minifyoptions)
  end

end

