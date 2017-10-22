class Apiinteractor
  attr_accessor :apiurl, :siteid, :pageid
  ##### Need api rewrite for this class
  def initialize(siteid)
    @apiurl = "http://localhost:3000"
  end

  def upload_file_to_private_site(filepath, position=nil)
    ####
    ####
    #### Some api methods to upload file to your site
    return uploaded_url
  end
end
