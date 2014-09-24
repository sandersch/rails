require 'helper'

class AdapterTest < ActiveSupport::TestCase
  test "should load #{ENV['AJADAPTER']} adapter" do
    ActiveJob::Base.queue_adapter = ENV['AJADAPTER'].to_sym
    assert_equal ActiveJob::Base.queue_adapter, "active_job/queue_adapters/#{ENV['AJADAPTER']}_adapter".classify.constantize
  end

  test 'should allow overriding the queue_adapter at the child class level without affecting the parent or its sibling' do
    base_queue_adapter = ActiveJob::Base.queue_adapter

    child_job_one = Class.new(ActiveJob::Base)
    child_job_one.queue_adapter = :test

    assert_not_equal ActiveJob::Base.queue_adapter, child_job_one.queue_adapter
    assert_equal ActiveJob::QueueAdapters::TestAdapter, child_job_one.queue_adapter

    child_job_two = Class.new(ActiveJob::Base)
    child_job_two.queue_adapter = :inline

    assert_equal ActiveJob::QueueAdapters::InlineAdapter, child_job_two.queue_adapter
    assert_equal ActiveJob::QueueAdapters::TestAdapter, child_job_one.queue_adapter, "child_job_one's queue adapter should remain unchanged"
    assert_equal base_queue_adapter, ActiveJob::Base.queue_adapter, "ActiveJob::Base's queue adapter should remain unchanged"

    child_job_three = Class.new(ActiveJob::Base)

    assert_not_nil child_job_three.queue_adapter
  end
end
