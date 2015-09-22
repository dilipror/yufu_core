module OrderWorkflow
  extend ActiveSupport::Concern

  # Order's workflow
  included do
    state_machine initial: :new do
      state :paying
      state :wait_offer
      state :additional_paying
      state :in_progress
      state :close
      state :rated

      event :paying do
        transition [:new] => :paying
      end

      event :paid do
        transition [:new, :paying, :additional_paying] => :wait_offer
      end

      event :unpaid do
        transition [:wait_offer, :additional_paying] => :paying
      end

      event :process do
        transition wait_offer: :in_progress
      end

      event :reject do
        transition in_progress: :wait_offer
      end

      event :close do
        transition  [:sent_to_client, :in_progress] => :close
      end

      # It should be after, but it doesn't work with MongoId https://github.com/pluginaweek/state_machine/issues/277
      before_transition on: :reject do |order|
        order.assignee = nil
      end

      before_transition on: :paid do |order|
        if order.is_a? Order::Verbal
          OrderWorkflowWorker.perform_in 24.hours, order.id, 'after_24'
          OrderWorkflowWorker.perform_in 12.hours, order.id, 'after_12'
          OrderWorkflowWorker.perform_in (order.first_date_time - 60.hours) - Time.now, order.id, 'before_60'
          OrderWorkflowWorker.perform_in (order.first_date_time - 48.hours) - Time.now , order.id, 'before_48'
          OrderWorkflowWorker.perform_in (order.first_date_time - 36.hours) - Time.now , order.id, 'before_36'
          OrderWorkflowWorker.perform_in (order.first_date_time - 24.hours) - Time.now, order.id, 'before_24'
          OrderWorkflowWorker.perform_in (order.first_date_time -  4.hours) - Time.now , order.id, 'before_4'
        end
      end

      before_transition on: :close do |order|
        # order.close_cash_flow
        order.after_close_cashflow
        order.notify_about_closing
        true
      end
    end
  end
end