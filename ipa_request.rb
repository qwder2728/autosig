# frozen_string_literal: true
require 'net/http'
require 'json'
require './app_log.rb'

class UploadError < StandardError

end

# upload ipa
class IpaRequest

  @@url_domain = 'https://www.quxunpack.cn'

  def self.set_domain(url_domain)
    @@url_domain = url_domain
    puts "domain is #{url_domain}"
  end

  def initialize(file_path, device_id)
    @file_path = file_path
    @device_id = device_id
  end

  def upload
    begin
      url = URI("#{@@url_domain}/Admin/API/index.php/geturl/index")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
      data = [['img', open(@file_path)]]
      request = Net::HTTP::Post.new(url.path)
      request.set_form(data, 'multipart/form-data')
      response = http.request(request)
      res = JSON.parse(response.body)
      return res['data'] if res['code'] == 1
    rescue Exception => e
      AppLog.instance.info e
    end
    raise UploadError.new, 'upload ipa error'
  end

  def self.complete(task_id, filepath)
	  url = URI.parse("#{@@url_domain}/upload.php")
    Net::HTTP.start(url.host, url.port, :use_ssl => (url.scheme == 'https')) do |http|
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data(task_id: task_id,
                        url: filepath,
                        info: 0)
      res = JSON.parse(http.request(req).body)
      puts res
      return if res['result'] == 1
    end  
  rescue Exception => e
    AppLog.instance.error e
  end

  def self.report_error(task_id, error_name)
    url = URI.parse("#{@@url_domain}/Admin/API/index.php/index/save_url")

    Net::HTTP.start(url.host, url.port, :use_ssl => (url.scheme == 'https')) do |http|
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data(task_id: task_id,
                        error: error_name,
                        info: 1)
      res = JSON.parse(http.request(req).body)
      return if res['result'] == 1
    end
  rescue Exception => e
    AppLog.instance.error e
  end

  def self.report_device_count_warning(name, device_count)
    url = URI.parse("#{@@url_domain}/Admin/API/index.php/index/save_message")

    Net::HTTP.start(url.host, url.port, :use_ssl => (url.scheme == 'https')) do |http|
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data(name: name, device_count: device_count)
      res = JSON.parse(http.request(req).body)
      return if res['result'] == 1
    end
  rescue Exception => e
    AppLog.instance.error e
  end
end
