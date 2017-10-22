module Utils
  def valid_path
    "#{@working_dir}/result/#{@api.siteid}"
  end

  def mkdirs
    FileUtils.mkdir_p "#{valid_path.to_s}"
    FileUtils.rm_f Dir.glob("#{valid_path}/*")
    FileUtils.mkdir_p "#{valid_path}/tmp_scripts"
    FileUtils.rm_f Dir.glob("#{valid_path}/tmp_scripts/*")
    FileUtils.mkdir_p "#{valid_path}/tmp_css"
    FileUtils.rm_f Dir.glob("#{valid_path}/tmp_css/*")
    FileUtils.mkdir_p "#{valid_path}/tmp_img"
    FileUtils.rm_f Dir.glob("#{valid_path}/tmp_img/*")
    FileUtils.rm_f Dir.glob("#{valid_path}/image/*")
    FileUtils.rm_f Dir.glob("#{valid_path}/css/*")
    FileUtils.rm_f Dir.glob("#{valid_path}/js/*")
    FileUtils.mkdir_p "#{valid_path}/tmpsites"
    FileUtils.mkdir_p "#{valid_path}/tmp"
    FileUtils.mkdir_p "#{valid_path}/image"
    FileUtils.mkdir_p "#{valid_path}/css"
    FileUtils.mkdir_p "#{valid_path}/js"
    FileUtils.mkdir_p "#{valid_path}/unknown"
    FileUtils.mkdir_p "#{valid_path}/font"
    FileUtils.mkdir_p "#{valid_path}/tmpsites/#{@api.siteid}"
    FileUtils.mkdir_p "#{valid_path}/parsed"
    FileUtils.rm_f Dir.glob("#{valid_path}/parsed/*")
    FileUtils.mkdir_p "#{valid_path}/parsed/#{@api.siteid}"
  end

  def write_rootpage(data)
    file = File.open("#{valid_path}/tmp/rootpage", 'w')
    file.write(data.to_s)
    file.close
  end

  def detect_url_or_base64data(url, css_obj=nil)
    if url.to_s =~ /^data.*/i
      url
    else
      if css_obj.nil?
        URI::join(@clonepage.url.to_s, url.to_s.strip)
      else
        URI::join(css_obj[:prepared_url].to_s, url.to_s.strip)
      end
    end
  end

  def prepare_image_url(imgobj, css_obj=nil)
    url = imgobj[:url]
    if url.to_s =~ /^http.*/i
      imgobj[:prepared_url] = url.to_s
    else
      imgobj[:prepared_url] = detect_url_or_base64data(url, css_obj)
    end
    imgobj
  end

  def prepare_css_image_url(css_image, css_obj)

  end

  def download_image(img_object)
    downloaded_path = @downloader.download(img_object[:prepared_url])
    img_object[:downloaded_path] = downloaded_path
    img_object
  end

  def upload_asset(filepath)
    result = @api.upload_file_to_private_site(filepath)
    result["asset_url"]
  end

  def prepare_base64_obj(im_object)
    im_object[:uploaded_url] = im_object[:prepared_url]
    im_object[:downloaded_path] = im_object[:prepared_url]
    im_object
  end

  def prepare_regular_link(im_object)
    im_object = download_image(im_object)
    uploaded_url = upload_asset(im_object[:downloaded_path])
    im_object[:uploaded_url] = uploaded_url
    return im_object
  end

  def download_upload_inline_images(imagearray)
    if imagearray.count > 0
      imagearray.each do |img_object|
        img_object = prepare_image_url(img_object)
        ### Do not download or upload url if it is a base64 image
        if img_object[:prepared_url].to_s =~ /^data\:.*/i
          img_object = prepare_base64_obj(img_object)
        else
          img_object = prepare_regular_link(img_object)
        end
      end
    end
  end

  def write_body_style_and_upload_to_server(styles)
    filepath = "#{valid_path}/css/bodystyles.css"
    file = File.open(filepath, 'w')
    file.write(styles)
    file.close
    upload_asset(filepath)
  end

  def prepare_and_download_cssfile(cssfileurl)
    cssfile_obj = @parser.found_css_link(cssfileurl)
    prepare_image_url(cssfile_obj)
    css_obj = download_image(cssfile_obj)
    css_obj
  end

  def download_upload_css_images(css_images, css_obj)
    images = []
    css_images.each do |img|
      prepared_image_obj = prepare_image_url(img, css_obj)
      ready_css_image = download_image(prepared_image_obj)
      uplloaded_asset_url = upload_asset(ready_css_image[:downloaded_path])
      ready_css_image[:uploaded_url] = uplloaded_asset_url
      images.push ready_css_image
    end
    images
  end

  def replace_css_imags(images, css_obj)
    filedata = File.read(css_obj[:downloaded_path])
    images.each do |img|
      filedata = filedata.to_s.gsub(img[:url].to_s, img[:uploaded_url])
    end
    cssfile = File.open(css_obj[:downloaded_path], 'w')
    cssfile.write(filedata)
    cssfile.close
  end

  def upload_css_file_for_website(css_obj, index)
    @api.upload_file_to_private_site(css_obj[:downloaded_path],index)
  end

  def write_ready_file_to_disk(data)
    file = File.open("#{valid_path}/tmpsites/#{@api.siteid}/#{@api.pageid}", 'w')
    file.write(data)
    file.close
    file
  end

  def parse_html_file_and_set_attrs
    @attrsetter.read_file
    @attrsetter.run
  end
end
