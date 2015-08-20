class Translation
  include Mongoid::Document

  MONGO_MODELS = %w(Language.name Order::Car.name City.name Order::Service.name Order::ServicesPack.name
                    Order::ServicesPack.short_description Order::ServicesPack.long_description Major.name
                    Order::Written::WrittenSubtype.name Order::Written::WrittenSubtype.description
                    Order::Written::WrittenType.name Order::Written::WrittenType.description)

  field :key
  field :value
  field :is_model_localization, type: Mongoid::Boolean, default: false

  belongs_to :version, class_name: 'Localization::Version'

  scope :model_localizers, ->{where is_model_localization: true }

  validates_presence_of :version

  def localize_model
    return unless is_model_localization?
    tmp = key.split('.')
    target_locale = version.localization.name
    klass = tmp[0].gsub('_', '::')
    klass = klass.constantize
    field = tmp[1].parameterize.underscore.to_sym
    id = tmp[2]

    que = klass.find_by(id: id)

    I18n.locale = target_locale
    que[field] = value
    que.save
  end
end