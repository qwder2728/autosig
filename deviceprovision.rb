# frozen_string_literal: true

require 'spaceship'
require './app_log.rb'

# DeviceProvision
class DeviceProvision
  def initialize(udid, device_name, config)
    @udid = udid
    @device_name = device_name
    @config = config
  end

  def register_device
    AppLog.instance.info "查找创建设备 #{@device_name}, #{@udid}"
    Spaceship.device.create!(name: @device_name, udid: @udid)
  end

  def devices_count
    Spaceship.device.all.size
  end

  def update_provision_file(device)
    AppLog.instance.info '开始获取provision文件列表'
    profiles = Array.new
    profiles += Spaceship.provisioning_profile.ad_hoc.all
    AppLog.instance.info '获取列表成功！'
    profiles.each do |p|
      next unless p.name == @config.provision_name

      exist_device = p.devices.find { |item| item.udid == @udid }

      AppLog.instance.info '生成新的provision profile'
      return p unless exist_device.nil?

      AppLog.instance.info "更新 #{p.name}"
      p.devices = [device]

      return p.update!
    end
  end

  def download_provision_file(profile)
    AppLog.instance.info '开始下载provision文件'
    File.write(@config.get_provision_profile_path(@udid), profile.download)
    AppLog.instance.info "成功下载文件到#{@config.get_provision_profile_path(@udid)}"
  end

  def run
    download_provision_file(update_provision_file(register_device))
  end
end