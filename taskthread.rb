# frozen_string_literal: true

# !/usr/bin/ruby
# coding=utf-8

require 'thread'

#
class TaskThread
  def initialize(block)
    @tasks = []
    @mutex = Mutex.new
    @stopped = false
    @resource = ConditionVariable.new
    @block = block
    @td = Thread.new {
      task = nil
      until @stopped
        @mutex.synchronize {
          timeout = !@tasks.empty? ? 0 : 100_000
          @resource.wait(@mutex, timeout)
          return if @stopped

          task = @tasks[0]
          @tasks.delete_at(0)
        }
        @block&.call(task)
      end
    }
  end

  def join
    @td.join
  end

  def stop
    @stopped = true
    @resource.signal
    join
  end

  def add_task(task)
    @mutex.synchronize {
      @tasks << task
      @resource.signal
    }
  end
end