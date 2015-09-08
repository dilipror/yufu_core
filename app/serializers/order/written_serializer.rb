class Order::WrittenSerializer < Order::BaseSerializer
  attributes :translation_type, :quantity_for_translate, :level, :second_level, :price, :original_language_id,
             :translation_language_id, :price_translate, :price_correct, :translation_file_name, :translation_url,
             :order_type_id, :order_subtype_id, :surcharge_for_postage
  has_one :get_original
  has_one :get_translation
  # has_one :client_info
  has_many :work_reports
  has_many :attachments

  # has_one :order_subtype

  # def order_subtype
  #   @object.order_subtype
  # end

  def surcharge_for_postage
    Order::Written.surcharge_for_postage(Currency.current_currency)
  end

  def translation_url
    object.translation.url
  end

end