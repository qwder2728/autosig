# frozen_string_literal: true

require 'logger'
require 'pathname'


# Log it
class AppLog
  private_class_method :new
  @@instance = nil
  @@log_folder = "#{Pathname.new(File.dirname(__FILE__)).realpath}/logs"
  @@log_file_name = 'log.txt'
  attr_reader :logger
  def initialize
    # STDOUT
    Dir.mkdir(@@log_folder) unless File.exist?(@@log_folder)
    @logger = Logger.new("#{@@log_folder}/#{@@log_file_name}", 'daily')
  end

  # must call before set_env
  def self.set_env(folder, name)
    @@log_folder = folder unless folder.nil?
    @@log_file_name = name unless name.nil?
  end

  def self.instance
    @@instance = new unless @@instance
    @@instance.logger
  end

end