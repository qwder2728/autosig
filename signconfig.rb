# frozen_string_literal: true

# config
class SignConfig

  attr_reader :file_path, :dest_folder, :signing_identity, :provision_name
  attr_reader :user_name, :password, :mq_queue_name, :key_pem_path, :certificate_pem_path
  attr_reader :p12_pass, :p12_path, :bundle_id

  def initialize(params)
    @file_path = params['file_path']
    @dest_folder = params['dest_folder']
    @certificate_pem_path = params['certificate_pem_path']
    @key_pem_path = params['key_pem_path']
    @signing_identity = params['signing_identity']
    @provision_name = params['provision_name']
    @user_name = params['user_name']
    @password = params['password']
    @mq_queue_name = params['mq_queue_name']
    @p12_pass = params['p12_pass']
    @p12_path = params['p12_path']
    @bundle_id = params['bundle_id']
  end

  def get_dest_ipa_path(udid)
    @dest_folder + "/#{udid}.ipa"
  end

  def get_provision_profile_path(udid)
    @dest_folder + "/#{udid}.mobileprovision"
  end

end