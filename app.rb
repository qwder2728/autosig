# frozen_string_literal: true

require 'bunny'
require 'json'
require 'pathname'
require 'spaceship'
require './signconfig.rb'
require './taskthread.rb'
require './deviceprovision.rb'
# require './signipa.rb'
require './linux_sign.rb'
require './ipa_request.rb'
require './app_log.rb'

# main
class App
  def initialize
    params = fetch_config_params
    AppLog.instance.info "app initialize 2 #{Dir.home} #{Dir.tmpdir}"
    puts params['domain']
    IpaRequest.set_domain(params['domain']) if params['domain'] != nil
    @sign_config = SignConfig.new(params)
    task_block = proc do |task|
      retry_count = 1
      while retry_count < 3
        retry_count += 1
        do_result = do_sign(task)
        if do_result['result']
          IpaRequest.complete(task['task_id'], do_result['info'])
          break
        elsif retry_count == 3
          IpaRequest.report_error(task['task_id'], do_result['info'])
        end
      end
    end
    @task_thread = TaskThread.new(task_block)
    @connection = Bunny.new(host: params['mq_host'],
                            port: params['mq_port'],
                            user: params['mq_user'],
                            pass: params['mq_pass'],
                            vhost: params['mq_vhost'])
    @connection.start
    @channel = @connection.create_channel
    @queue = @channel.queue(@sign_config.mq_queue_name)
    # @callback_queue = @channel.queue('resign_callback')
  end

  def run
    @queue.subscribe(block: true) do |_delivery_info, _properties, body|
      begin
        AppLog.instance.info "queue message #{body}"
        add_sign_task(JSON.parse(body))
      rescue Exception => e
        AppLog.instance.error e
      end
    end
  rescue Interrupt => _e
    AppLog.instance.info _e
    close
  end

  # def send(text)
  #   @channel&.default_exchange&.publish('sign ok',
  #                                       routing_key: @callback_queue.name)
  # end

  def close
    @queue = nil
    @callback_queue = nil
    @channel.close
    @channel = nil
    @connection.close
    @connection = nil
  end

  def add_sign_task(params)
    device_id = params['device_id']
    device_name = params['deviceName'] || device_id
    task_id = params['task_id']
    raise ArgumentError, 'invalid device id' if device_id.nil? || task_id.nil?

    @task_thread.add_task('device_id' => device_id,
                          'device_name' => device_name, 'task_id' => task_id)
  end

  def do_sign(sign_info)
    AppLog.instance.info "do sign start with param #{sign_info}"
    result = { result: false }
    begin
      # 0. 登录developer
      AppLog.instance.info 'start login'
      AppLog.instance.info "start login #{@sign_config.user_name} #{@sign_config.password}"
      Spaceship.login(@sign_config.user_name, @sign_config.password)
      # 1. 注册设备并下载对应的provision file
      device_provision = DeviceProvision.new(sign_info['device_id'],
                                             sign_info['device_name'],
                                             @sign_config)
      device_provision.run
      # 获取设备数量
      device_count = device_provision.devices_count
      AppLog.instance.info "current device count is #{device_count}"
      if (device_count == 95 || device_count == 90 || device_count == 98 || device_count >= 100)
        # send message to mobile
        IpaRequest.report_device_count_warning(@sign_config.user_name,
                                               device_count)
      end
      # 2. 签名
      sign_ipa = SignIpa.new(sign_info['device_id'], @sign_config)
      ipa_file_path = sign_ipa.resign
      # 3. 上传文件
      # upload_request = IpaRequest.new(ipa_file_path, sign_info['device_id'])
      # ipa_url = upload_request.upload
      result['result'] = true
      result['info'] = ipa_file_path
    rescue Exception => e
      AppLog.instance.error 'exception info'
      AppLog.instance.error e
      AppLog.instance.error 'exception code location'
      AppLog.instance.error $@
      result['info'] = e.message
    ensure
      sign_ipa&.clear_cache
    end

    AppLog.instance.info "do sign end #{sign_info['device_id']} result is #{result['result']}"

    result

  end

  def fetch_config_params
    index = ARGV.index('--filepath')
    raise ArgumentError, 'invalid file path' if index.nil?

    Process.daemon unless ARGV.index('-d').nil?

    file_path = ARGV.at(index + 1)
    root_path = File.dirname(Pathname.new(__FILE__).realpath)
    file_path = "#{root_path}/#{file_path}" if file_path.index('/').nil?

    params = JSON.parse(File.read(file_path))

    # 设置日志文件
    AppLog.set_env("#{params['dest_folder']}/logs", "#{params['mq_queue_name']}.log")

    unless ARGV.index('-l').nil?
      begin
        Spaceship.login(params['user_name'], params['password'])
        AppLog.instance.info 'login successfully'
      rescue Exception => e
        AppLog.instance.error e
      end
    end

    params
  end

  private :send, :close, :do_sign, :fetch_config_params, :add_sign_task

end

app = App.new
app.run
