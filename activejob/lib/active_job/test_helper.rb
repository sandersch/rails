require 'active_support/core_ext/class/subclasses'

module ActiveJob
  # Provides helper methods for testing Active Job
  module TestHelper
    extend ActiveSupport::Concern

    included do
      def before_setup
        @old_queue_adapters = (ActiveJob::Base.subclasses << ActiveJob::Base).select do |klass|
          klass.methods(false).include?(:_queue_adapter)
        end.map do |klass|
          [klass, klass._queue_adapter].tap do
            klass.queue_adapter = :test
          end
        end

        clear_enqueued_jobs
        clear_performed_jobs
        super
      end

      def after_teardown
        super
        @old_queue_adapters.each do |(klass, adapter)|
          klass._queue_adapter = adapter
        end
      end

      # Asserts that the number of enqueued jobs matches the given number.
      #
      #   def test_jobs
      #     assert_enqueued_jobs 0
      #     HelloJob.perform_later('david')
      #     assert_enqueued_jobs 1
      #     HelloJob.perform_later('abdelkader')
      #     assert_enqueued_jobs 2
      #   end
      #
      # If a block is passed, that block should cause the specified number of
      # jobs to be enqueued.
      #
      #   def test_jobs_again
      #     assert_enqueued_jobs 1 do
      #       HelloJob.perform_later('cristian')
      #     end
      #
      #     assert_enqueued_jobs 2 do
      #       HelloJob.perform_later('aaron')
      #       HelloJob.perform_later('rafael')
      #     end
      #   end
      def assert_enqueued_jobs(number)
        if block_given?
          original_count = enqueued_jobs.size
          yield
          new_count = enqueued_jobs.size
          assert_equal original_count + number, new_count,
                       "#{number} jobs expected, but #{new_count - original_count} were enqueued"
        else
          enqueued_jobs_size = enqueued_jobs.size
          assert_equal number, enqueued_jobs_size, "#{number} jobs expected, but #{enqueued_jobs_size} were enqueued"
        end
      end

      # Assert that no job have been enqueued.
      #
      #   def test_jobs
      #     assert_no_enqueued_jobs
      #     HelloJob.perform_later('jeremy')
      #     assert_enqueued_jobs 1
      #   end
      #
      # If a block is passed, that block should not cause any job to be enqueued.
      #
      #   def test_jobs_again
      #     assert_no_enqueued_jobs do
      #       # No job should be enqueued from this block
      #     end
      #   end
      #
      # Note: This assertion is simply a shortcut for:
      #
      #   assert_enqueued_jobs 0
      def assert_no_enqueued_jobs(&block)
        assert_enqueued_jobs 0, &block
      end

      # Asserts that the number of performed jobs matches the given number.
      #
      #   def test_jobs
      #     assert_performed_jobs 0
      #     HelloJob.perform_later('xavier')
      #     assert_performed_jobs 1
      #     HelloJob.perform_later('yves')
      #     assert_performed_jobs 2
      #   end
      #
      # If a block is passed, that block should cause the specified number of
      # jobs to be performed.
      #
      #   def test_jobs_again
      #     assert_performed_jobs 1 do
      #       HelloJob.perform_later('robin')
      #     end
      #
      #     assert_performed_jobs 2 do
      #       HelloJob.perform_later('carlos')
      #       HelloJob.perform_later('sean')
      #     end
      #   end
      def assert_performed_jobs(number)
        if block_given?
          original_count = performed_jobs.size
          yield
          new_count = performed_jobs.size
          assert_equal original_count + number, new_count,
                       "#{number} jobs expected, but #{new_count - original_count} were performed"
        else
          performed_jobs_size = performed_jobs.size
          assert_equal number, performed_jobs_size, "#{number} jobs expected, but #{performed_jobs_size} were performed"
        end
      end

      # Asserts that no jobs have been performed.
      #
      #   def test_jobs
      #     assert_no_performed_jobs
      #     HelloJob.perform_later('matthew')
      #     assert_performed_jobs 1
      #   end
      #
      # If a block is passed, that block should not cause any job to be performed.
      #
      #   def test_jobs_again
      #     assert_no_performed_jobs do
      #       # No job should be performed from this block
      #     end
      #   end
      #
      # Note: This assertion is simply a shortcut for:
      #
      #   assert_performed_jobs 0
      def assert_no_performed_jobs(&block)
        assert_performed_jobs 0, &block
      end

      # Asserts that the job passed in the block has been enqueued with the given arguments.
      #
      #   def assert_enqueued_job
      #     assert_enqueued_with(job: MyJob, args: [1,2,3], queue: 'low') do
      #       MyJob.perform_later(1,2,3)
      #     end
      #   end
      def assert_enqueued_with(args = {}, &block)
        matching_job = matching_verbed_job(:enqueued_jobs, args, &block)
        assert matching_job, "No enqueued job found with #{args}"
      end

      # Asserts that the job passed in the block has been performed with the given arguments.
      #
      #   def test_assert_performed_with
      #     assert_performed_with(job: MyJob, args: [1,2,3], queue: 'high') do
      #       MyJob.perform_later(1,2,3)
      #     end
      #   end
      def assert_performed_with(args = {}, &block)
        matching_job = matching_verbed_job(:performed_jobs, args, &block)
        assert matching_job, "No performed job found with #{args}"
      end

      def queue_adapter
        ActiveJob::Base.queue_adapter
      end

      delegate :enqueued_jobs, :performed_jobs, to: :queue_adapter

      private
        def matching_verbed_job(verb, args, &_block)
          args.assert_valid_keys(:job, :args, :at, :queue)

          already_verbed_jobs = send(verb).length
          yield
          verbed_jobs = send(verb)
          verbed_jobs.drop(already_verbed_jobs).any? do |job|
            args.all? { |key, value| value == job[key] }
          end
        end

        def clear_enqueued_jobs
          enqueued_jobs.clear
        end

        def clear_performed_jobs
          performed_jobs.clear
        end
    end
  end
end
