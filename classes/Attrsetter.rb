class Attrsetter
  attr_reader :filepath, :htmldata, :jsondata, :allnodes

  def initialize(path)
    @filepath = path
    @jsondata = {}
    @allnodes = []
  end

  def find_parenttextnodes(path,doc)
    result = ''
    arr = path.split("/")
    arr.delete("")
    arr.each_with_index do |elem, index|
      newpath = arr.each_with_index.map { |a,i| a if i <= index }
      readypath = newpath.compact.join("/")
      txtcount = doc.xpath("/#{readypath}/text()").count
      if txtcount.to_i > 0
        result = "/#{readypath}"
        break
      end
    end
    result
  end

  def read_file
    file = File.read(@filepath)
    @htmldata = Nokogiri::HTML(file)
  end

  def remove_comments
    comments = @htmldata.xpath("//comment()")
    comments.remove
  end

  def clear_wrong_attributes
    @htmldata.traverse do |node|
      node.keys.each do |attribute|
        if attribute.to_s.include?(".")
          node.delete attribute
        end
      end
    end
  end

  def prepare_nodes
    @htmldata.traverse {|block| @allnodes << block}
  end

  def generate_id_for_elements
    @allnodes.each do |node|
      uuid = SecureRandom.hex.to_s
      if node.type.to_s == '1'
        node["elementid"] = "el"+uuid
        @jsondata["el#{uuid}"] = {}
      end
    end
  end

  def prepare_text_elements
    textelements = @htmldata.xpath("//text()")
    textelements.each do |elem|
      readypath = find_parenttextnodes(elem.path,@htmldata)
      if readypath.to_s != ''
        myelem = @htmldata.xpath(readypath)
        uuid = myelem.attr("elementid").to_s
        myelem.attr('ng-model',"sitecontent.#{uuid}.text")
        myelem.attr('ui-tinymce',"tinymceOptions")
        data = myelem.children.to_s
        myelem.children.remove
        @jsondata[uuid]['text'] = data
      end
    end
  end

  def setting_style_class_attrs
    @allnodes.each do |node|
      if node.type.to_s == '1'
        node["class"]
        uuid = node["elementid"]
        node['ng-style'] = "sitecontent.#{uuid}.style"
        node['ng-class'] = "sitecontent.#{uuid}.classes"
        @jsondata[uuid]['style'] = {}
        @jsondata[uuid]['classes'] = node["class"]
        node["class"] = ''
      end
    end
  end

  def setting_attrs
    links = @htmldata.xpath("//a")
    links.each do |a|
      hrefvalue = a['href'].to_s
      uuid = a["elementid"]
      @jsondata[uuid]['href'] = hrefvalue
      a["href-model"] = "sitecontent.#{uuid}.href"
      a["ng-href"] = "{{sitecontent.#{uuid}.href}}"
    end
  end

  def setting_img_attrs
    @allnodes.each do |node|
      if node.name.to_s == 'img'
        if node["src"]
          srcval = node["src"]
          uuid = node['elementid'].to_s
          node['ng-src'] = "{{sitecontent.#{uuid}.src}}"
          @jsondata[uuid]['src'] = srcval
        end
      end
    end
  end

  def setting_placeholder_attr_for_inputs
    @allnodes.each do |node|
      if node.name.to_s == 'input'
        if node['placeholder']
          uuid = node['elementid'].to_s
          @jsondata[uuid]['placeholder'] = node['placeholder']
          node['placeholder'] = "{{sitecontent.#{uuid}.placeholder}}"
        end
      end
    end
  end

  def setting_iframe_src_attr
    @allnodes.each do |node|
      if node.name.to_s == 'iframe'
        if node['src']
          uuid = node['elementid'].to_s
          @jsondata[uuid]['framesrc'] = node['src']
          node['src'] = ""
          node['ng-src'] = "{{sitecontent.#{uuid}.framesrc}}"
        end
      end
    end
  end

  def save_json_to_file(fp)
    jsonfile = File.open("#{fp}.json", 'w')
    jsonfile.puts @jsondata.to_json
    jsonfile.close
  end
  def save_html_to_file(fp)
    compressed_html = @htmldata.to_xhtml
    tempfile = File.open("#{fp}.html", 'w')
    tempfile.puts compressed_html
    tempfile.close
  end

  def prepare_and_save_to_file
    puts @filepath
    newfilepath = @filepath.split("/")
    newfilepath =  newfilepath.each {|x| x.gsub!("tmpsites", "parsed")}
    fp = newfilepath.join("/")
    newfilepath.pop
    save_json_to_file(fp)
    save_html_to_file(fp)
  end

  def run
    remove_comments
    clear_wrong_attributes
    prepare_nodes
    generate_id_for_elements
    prepare_text_elements
    setting_style_class_attrs
    setting_attrs
    setting_img_attrs
    setting_placeholder_attr_for_inputs
    setting_iframe_src_attr
    prepare_and_save_to_file
  end
end