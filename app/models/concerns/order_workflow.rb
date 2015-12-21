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
      state :canceled_by_not_paid
      state :canceled_by_client
      state :canceled_by_yufu

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

      event :close do
        transition  [:sent_to_client, :in_progress] => :close
      end

      event :cancel_by_yufu do
        transition [:new, :paying] => :canceled_by_yufu
      end

      event :cancel_by_client do
        transition all - [:canceled_by_yufu, :canceled_by_not_paid, :canceled_by_client, :in_progress, :sent_to_client, :close, :rated] => :canceled_by_client
      end

      event :cancel_by_not_paid do
        transition [:new, :paying] => :canceled_by_not_paid
      end

      # It should be after, but it doesn't work with MongoId https://github.com/pluginaweek/state_machine/issues/277
      before_transition on: [:cancel_by_not_paid, :cancel_by_client, :cancel_by_yufu] do |order|
        order.try :remove_busy_days
        order.assignee = nil
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