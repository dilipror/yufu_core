class Order::VerbalSerializer < Order::BaseSerializer
  attributes :id, :include_near_city, :goal, :location_name, :reservation_dates_count, :location_id,
             :want_native_chinese, :can_confirm, :can_update, :level, :language_id,
             :there_are_translator, :greeted_at, :meeting_in, :can_send_secondary_offer, :can_send_primary_offer,
             :offer_status, :offers, :do_not_want_native_chinese

  has_one :main_language_criterion
  has_one :airport_pick_up
  has_one :car_rent
  has_one :hotel
  has_one :client_info
  has_many :offers
  has_many :reserve_language_criterions
  has_many :reservation_dates
  has_many :directions

  def offer_status
    object.offer_status_for @scope
  end

  def can_send_primary_offer
    @object.can_send_primary_offer?
  end

  def can_send_secondary_offer
    @object.can_send_secondary_offer?
  end

  def there_are_translator
    @object.there_are_translator_with_surcharge?
  end

  def can_confirm
    if object.reservation_dates.count > 0
      return (object.first_date - Date.today).day <= 1.day
    else
      return false
    end
  end

  def directions
    object.direction_ids
  end

  def reservation_dates_count
    object.reservation_dates.count
  end
end
