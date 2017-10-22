require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'securerandom'
require 'css_parser'
require 'csspool'
require 'rest-client'
require 'json'
require 'nokogiri-styles'
require 'pathname'
require 'html_press'
require 'html_minifier'
require 'open_uri_redirections'
require 'headless'
require 'watir'
require 'watir-scroll'
require 'uri'
require File.dirname(__FILE__).to_s + '/utils.rb'
require File.dirname(__FILE__).to_s + '/classes/Clonepage.rb'
require File.dirname(__FILE__).to_s + '/classes/Siteinfo.rb'
require File.dirname(__FILE__).to_s + '/classes/Mybrowser.rb'
require File.dirname(__FILE__).to_s + '/classes/Nokogiriparser.rb'
require File.dirname(__FILE__).to_s + '/classes/Downloader.rb'
require File.dirname(__FILE__).to_s + '/classes/Apiinteractor.rb'
require File.dirname(__FILE__).to_s + '/classes/Htmlparser.rb'
require File.dirname(__FILE__).to_s + '/classes/Attrsetter.rb'
include Utils

puts "Starting to perform cloner"

path = ARGV[0]
siteid = ARGV[1]
siteid = 'XXXX'
@pageid = 'XXX'
@working_dir = '/tmp'



@clonepage = Clonepage.new(path)
@api = Apiinteractor.new(siteid)
@downloader = Downloader.new(valid_path)
browser  = Mybrowser.new(@clonepage.url)
doc = browser.nokogiribody
noko = Nokogiriparser.new(doc)
mkdirs

write_rootpage(noko.html)

### DO NOT CREATE PAGE TEMP
#pageid = api.create_page("rootpage")
### DO NOT CREATE PAGE TEMP
data = File.read("#{valid_path}/tmp/rootpage")
pagedata = Nokogiri::HTML(data)
@parser = Htmlparser.new(pagedata)

### Finding images in style Aattributes
inlineimages = @parser.find_inline_images
download_inline_images = download_upload_inline_images(inlineimages) if inlineimages.count > 0
@parser.replace_inline_images_with_valid_url(download_inline_images)
### Finding images in Link href and upload them to server
in_link_href_images = @parser.find_images_in_link_href
download_in_link_href_images = download_upload_inline_images(in_link_href_images) if in_link_href_images.count > 0
@parser.replace_images_url_in_link_href(download_in_link_href_images)
### Finding images and uploading them to server by img tag
img_tag_images = @parser.find_images_img_tag
download_img_tag_images = download_upload_inline_images(img_tag_images) if img_tag_images.count > 0
@parser.replace_images_img_tag(download_img_tag_images)
#### Finding images in Inline css style tags
css_style_images = @parser.find_images_inside_css_styles_inside_html_page
download_i_css_styles_images = download_upload_inline_images(css_style_images) if css_style_images.count > 0
inline_styles = @parser.replace_inline_css_styles_images(download_i_css_styles_images)
#### CONCAT body STYLES and inline styles to one css file and Save it to disk
ready_inline_styles = @parser.get_body_styles
full_inline_styles = inline_styles.concat("body{#{ready_inline_styles}}")
write_body_style_and_upload_to_server(full_inline_styles)

### Parsing CSS styles and change url of images
cssfiles = @parser.get_linkhref_styles
cssfiles.each_with_index do |cssfile, cssindex|
  if !cssfile["href"].to_s.empty?
    css_obj = prepare_and_download_cssfile(cssfile["href"])
    cssdata = File.read(css_obj[:downloaded_path].to_s)
    css_images = @parser.find_image_inside_css(cssdata)
    if !css_images.nil?
      uploaded_css_images = download_upload_css_images(css_images, css_obj)
      replace_css_imags(uploaded_css_images, css_obj)
    end
    upload_css_file_for_website(css_obj, cssindex)
  end
end
@parser.clear_html
@parser.clear_wrong_attributes_and_tags
readyhtml = @parser.minify_html
file = write_ready_file_to_disk(readyhtml)
@attrsetter = Attrsetter.new(file.path)
parse_html_file_and_set_attrs

puts "Ready!"
