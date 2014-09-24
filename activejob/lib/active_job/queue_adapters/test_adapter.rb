module ActiveJob
  module QueueAdapters
    # == Test adapter for Active Job
    #
    # The test adapter should be used only in testing. Along with
    # <tt>ActiveJob::TestCase</tt> and <tt>ActiveJob::TestHelper</tt>
    # it makes a great tool to test your Rails application.
    #
    # To use the test adapter set queue_adapter config to +:test+.
    #
    #   Rails.application.config.active_job.queue_adapter = :test
    class TestAdapter
      class << self
        attr_accessor(:perform_enqueued_jobs, :perform_enqueued_at_jobs)

        # Provides a store of all the enqueued jobs with the TestAdapter so you can check them.
        def enqueued_jobs
          @enqueued_jobs ||= []
        end

        # Provides a store of all the performed jobs with the TestAdapter so you can check them.
        def performed_jobs
          @performed_jobs ||= []
        end

        def enqueue(job) #:nodoc:
          hash = job_to_hash(job)

          if perform_enqueued_jobs
            performed_jobs << hash
            job.perform_now
          else
            enqueued_jobs << hash
          end
        end

        def enqueue_at(job, timestamp) #:nodoc:
          hash = job_to_hash(job, at: timestamp)

          if perform_enqueued_at_jobs
            performed_jobs << hash
            job.perform_now
          else
            enqueued_jobs << hash
          end
        end

        private
          def job_to_hash(job, extras = {})
            {job: job.class, args: job.arguments, queue: job.queue_name}.merge(extras)
          end
      end
    end
  end
end
