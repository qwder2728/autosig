# frozen_string_literal: true
require 'fileutils'
require './app_log.rb'

# linux
class SignIpa
  def initialize(udid, config)
    @udid = udid
    @config = config
  end

  def clear_cache
    dest_file_path = @config.get_dest_ipa_path(@udid)
    provision_file_path = @config.get_provision_profile_path(@udid)
    AppLog.instance.info "clear #{dest_file_path} #{provision_file_path}"
    # File.delete(dest_file_path) if File.exist?(dest_file_path)
    File.delete(provision_file_path) if File.exist?(provision_file_path)
  end

  def resign
    dest_file_path = @config.get_dest_ipa_path(@udid)

    AppLog.instance.info '拷贝IPA文件'

    Dir.mkdir(@config.dest_folder) unless File.exist?(@config.dest_folder)
    File.delete(dest_file_path) if File.exist?(dest_file_path)
    # FileUtils.cp(@config.file_path, dest_file_path) if File.exist?(@config.file_path)

    AppLog.instance.info '重新打包IPA'

    command = ['zsign',
               "-k #{@config.p12_path}",
               "-p #{@config.p12_pass}",
               "-b '#{@config.bundle_id}'",
               "-m #{@config.get_provision_profile_path(@udid)}",
               "-o #{dest_file_path}",
               @config.file_path].join(' ')

    puts(command)
    puts(`#{command}`)

    raise '打包失败' unless File.exist?(dest_file_path)

    AppLog.instance.info "打包成功 #{dest_file_path}"

    dest_file_path
  end
end