# frozen_string_literal: true

require 'fileutils'
require 'sigh'
require './app_log.rb'

# sign and make new ipa
class SignIpa
  def initialize(udid, config)
    @udid = udid
    @config = config
  end

  def clear_cache
    dest_file_path = @config.get_dest_ipa_path(@udid)
    provision_file_path = @config.get_provision_profile_path(@udid)
    AppLog.instance.info "clear #{dest_file_path} #{provision_file_path}"
    File.delete(dest_file_path) if File.exist?(dest_file_path)
    File.delete(provision_file_path) if File.exist?(provision_file_path)
  end

  def resign
    dest_file_path = @config.get_dest_ipa_path(@udid)

    AppLog.instance.info '拷贝IPA文件'

    Dir.mkdir(@config.dest_folder) unless File.exist?(@config.dest_folder)
    File.delete(dest_file_path) if File.exist?(dest_file_path)
    FileUtils.cp(@config.file_path, dest_file_path) if File.exist?(@config.file_path)

    AppLog.instance.info '重新打包IPA'

    Sigh::Resign.resign(dest_file_path,
                        @config.signing_identity,
                        @config.get_provision_profile_path(@udid),
                        nil, nil, nil, nil,
                        nil, nil, nil, nil)

    AppLog.instance.info "打包成功 #{dest_file_path}"

    dest_file_path
  end
end