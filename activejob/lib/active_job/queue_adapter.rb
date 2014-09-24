require 'active_job/queue_adapters/inline_adapter'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'

module ActiveJob
  module QueueAdapter
    extend ActiveSupport::Concern

    included do
      class_attribute :_queue_adapter, instance_accessor: false, instance_predicate: false
      self.queue_adapter = :inline
    end

    module ClassMethods
      def queue_adapter
        if _queue_adapter.respond_to?(:call)
          interpret_adapter(_queue_adapter.call)
        else
          _queue_adapter
        end
      end

      def queue_adapter=(name_or_adapter_or_proc)
        self._queue_adapter = interpret_adapter(name_or_adapter_or_proc)
      end

      private
        def interpret_adapter(name_or_adapter_or_proc)
          case name_or_adapter_or_proc
          when Symbol, String
            load_adapter(name_or_adapter_or_proc)
          when Class
            name_or_adapter_or_proc
          else
            name_or_adapter_or_proc if name_or_adapter_or_proc.respond_to?(:call)
          end
        end

        def load_adapter(name)
          "ActiveJob::QueueAdapters::#{name.to_s.camelize}Adapter".constantize
        end
    end
  end
end
