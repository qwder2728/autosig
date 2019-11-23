# frozen_string_literal: true
# -*- coding: UTF-8 -*-

require 'bunny'
require 'json'
require 'pathname'
require 'spaceship'
require './signconfig.rb'
require './taskthread.rb'

connection = Bunny.new(host: '23.91.101.176',
                        port: 5672,
                        user: 'autosign',
                        pass: '12345678',
                        vhost: '/autosign')
connection.start
channel = connection.create_channel

channel&.default_exchange&.publish('{"device_id":"bd2168bd31069ca0e730cc37f16c57bcb6e73a51", "task_id":"06CrGGly"}',
                                      routing_key: 'resign_queue_1')
