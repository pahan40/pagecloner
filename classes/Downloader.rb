class Downloader
  attr_accessor :working_path
  def initialize(path)
    @working_path = path
    puts @working_path
  end
  def download(url)
    filename = getname(url)
    filetype = gettype(filename)
    begin
      filedata = open(url).read
    rescue => e
      puts "WARNING: COuld not download asset - #{url}"
      puts "Reason Download Failed: #{e.inspect}"
      filedata = '404 - NOT FOUND'
    end
    File.write "#{@working_path}/" + filetype.to_s + "/" + filename.to_s, filedata
    return "#{@working_path}/" + filetype.to_s + "/" + filename.to_s
  end


  def getname(url)
    url.to_s.split('/').last.gsub(/\?.*/i, '')
  end

  def gettype(filename)
    case filename.to_s
      when /.*\.png|svg|jpg|jpeg|bmp|cur|gif.*/i
        filetype = 'image'
      when /.*\.css|scss|less.*/i
        filetype = 'css'
      when /.*\.js.*/i
        filetype = 'js'
      when /.*\.woff|ttf|otf|fnt|fon|woff2.*/i
        filetype = 'font'
      else
        filetype = 'unknown'
    end
    filetype
  end
end