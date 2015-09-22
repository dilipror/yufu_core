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
  belongs_to :next, class_name: 'Translation', inverse_of: :previous

  has_one :previous, class_name: 'Translation', inverse_of: :next, dependent: :nullify

  scope :model_localizers, ->{where is_model_localization: true }
  scope :not_model_localizers, ->{where is_model_localization: false }
  scope :actual, -> {where next_id: nil}

  validates_presence_of :version
  after_save :wear_out

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

  def original
    I18n.t key
  end

  def self.all_translation_by_version(version)
    exist_in_version = version.translations
    keys_exists_in_version = exist_in_version.distinct(:key)
    other = Translation.all_in(version.localization).where :key.nin => keys_exists_in_version
    keys_in_other = other.distinct(:key)
    fallbacks = Translation.all_in(Localization.default).where :key.nin => (keys_exists_in_version + keys_in_other)
    Translation.not_model_localizers.any_of exist_in_version.selector, other.selector, fallbacks.selector
  end

  def self.all_in(localization)
    version_ids = localization.localization_versions.distinct(:id)
    exist_in_locale = Translation.where(:version_id.in => version_ids)
    original_locale = Localization.find_by name: I18n.locale
    original_available_versions = original_locale.localization_versions.approved.distinct(:id)
    Translation.actual.any_of(exist_in_locale.selector,
                              {:version_id.in => original_available_versions, :key.nin => exist_in_locale.distinct(:key)})
  end

  def self.only_updated(version)
    if version.english? || version.independent?
      version.translations
    else
      last_approved_version_with_parent = version.localization.localization_versions
                                              .dependent.approved.where(:id.lte => version.id).desc(:id).first.try(:id)
      cond = {:id.lte => version.parent_version_id}
      cond[:id.gt] = last_approved_version_with_parent if last_approved_version_with_parent.present?

      version_ids = Localization::Version.english.where(cond).distinct :id

      Translation.where(:version_id.in => version_ids)
    end
  end


  private
  def wear_out
    version_ids = version.localization.localization_versions.where(:_id.lt => id).distinct(:id)
    Translation.actual.where(:id.ne => id, :key => key, :version_id.in => version_ids).update_all next_id: id
  end
end