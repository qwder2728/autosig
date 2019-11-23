# frozen_string_literal: true

require 'json'
require 'pathname'
require './signconfig.rb'
require './signipa.rb'
require './deviceprovision.rb'
require './app_log.rb'

def fetch_config_params
  index = ARGV.index('--filepath')
  raise 'invalid param' if index.nil?

  file_path = ARGV.at(index + 1)
  root_path = File.dirname(Pathname.new(__FILE__).realpath)
  file_path = "#{root_path}/#{file_path}" if file_path.index('/').nil?

  JSON.parse(File.read(file_path))
end

# udid = "bd2168bd31069ca0e730cc37f16c57bcb6e73a51"
udid = '00008020-001859EE3EE9002E'
sign_config = SignConfig.new(fetch_config_params)

begin
  # 0. 登录developer
  Spaceship.login(sign_config.user_name, sign_config.password)
  # 1. 注册设备并下载对应的provision file
  device_provision = DeviceProvision.new(udid, "iPhone", sign_config)
  device_provision.run
  # 2. 签名
  sign_ipa = SignIpa.new(udid, sign_config)
  sign_ipa.resign
rescue Exception => e
  AppLog.instance.error "exception info"
  AppLog.instance.error e
  AppLog.instance.error "exception code location"
  AppLog.instance.error $@
end
