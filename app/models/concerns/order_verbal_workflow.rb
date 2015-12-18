module OrderVerbalWorkflow
  extend ActiveSupport::Concern

  included do
    state_machine initial: :new do
      state :confirmed
      state :confirmation_delay
      state :translator_not_found
      state :need_reconfirm
      state :main_reconfirm_delay
      state :reconfirm_delay
      state :in_progress
      state :ready_for_close


      event :confirm do
        transition [:wait_offer, :confirmation_delay, :translator_not_found] => :confirmed
      end

      event :confirmation_delay do
        transition wait_offer: :confirmation_delay
      end

      event :translator_not_found do
        transition confirmation_delay: :translator_not_found
      end

      event :to_reconfirm do
        transition confirmed: :need_reconfirm
      end

      event :reject_confirm_before_12 do
        transition confirmed: :wait_offer
      end

      event :reject_confirm_after_12 do
        transition confirmed: :confirmation_delay
      end

      event :process do
        transition [:need_reconfirmed, :main_reconfirm_delay, :reconfirm_delay] => :in_progress
      end

      event :main_reconfirm_delay do
        transition need_reconfirm: :main_reconfirm_delay
      end

      event :reconfirm_delay do
        transition main_reconfirm_delay: :reconfirm_delay
      end

      event :cancel_by_yufu do
        transition [:reconfirm_delay, :confirmation_delay, :paying, :new] => :canceled_by_yufu
      end

      event :finish_order do
        transition [:in_progress] => :ready_for_close
      end

      event :close do
        transition  [:ready_for_close] => :close
      end

      before_transition on: :process do |order|
        order.update assignee: order.try(:primary_offer).try(:translator)
        order.notify_about_processing
        order.try :set_busy_days
        true
      end

      before_transition on: :paid do |order|
        OrderVerbalQueueFactoryWorker.perform_later order.id.to_s, I18n.locale.to_s
        OrderWorkflowWorker.set(wait: 24.hours).perform_later order.id.to_s, 'after_24'
        OrderWorkflowWorker.set(wait: 12.hours).perform_later order.id.to_s, 'after_12'
        OrderWorkflowWorker.set(wait: (order.first_date_time - 60.hours - Time.now)).perform_later order.id.to_s, 'before_60'
        OrderWorkflowWorker.set(wait: (order.first_date_time - 48.hours - Time.now)).perform_later order.id.to_s, 'before_48'
        OrderWorkflowWorker.set(wait: (order.first_date_time - 36.hours - Time.now)).perform_later order.id.to_s, 'before_36'
        OrderWorkflowWorker.set(wait: (order.first_date_time - 24.hours - Time.now)).perform_later order.id.to_s, 'before_24'
        OrderWorkflowWorker.set(wait: (order.first_date_time -  4.hours - Time.now)).perform_later order.id.to_s, 'before_4'
        CloseVerbalJob.set(wait: (order.last_date_time.to_time - Time.now)).perform_later order.id.to_s, 'finish_order'
        CloseVerbalJob.set(wait: (order.last_date_time.to_time - Time.now + 3.days)).perform_later order.id.to_s, 'close'
        order.update paid_time: Time.now
      end
    end
  end
end