module Textris
  module Delay
    module ActiveJob
      class Job < ::ActiveJob::Base
        queue_as :textris

        def perform(texter, action, *args, **kwargs)
          texter = texter.safe_constantize

          if texter.present?
            texter.new(action, *args, **kwargs).call_action.deliver_now
          end
        end
      end
    end
  end
end
