class Translation
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps

  field :key
  field :value
  field :is_model_localization, type: Mongoid::Boolean, default: false
  field :value_is_array, type: Mongoid::Boolean, default: false

  belongs_to :version, class_name: 'Localization::Version'
  belongs_to :next, class_name: 'Translation', inverse_of: :previous

  has_one :previous, class_name: 'Translation', inverse_of: :next, dependent: :nullify

  scope :model_localizers, ->{where is_model_localization: true }
  scope :not_model_localizers, ->{where is_model_localization: false }
  # DEPRECATED
  scope :actual, -> {where next_id: nil}
  scope :approved, -> {where :version_id.in => Localization::Version.approved.distinct(:id)}
  scope :seo, -> {where(key: /Order_ServicesPack.meta/).merge where(key: /^frontend\.meta_tags\./)}
  scope :notifications, -> {where( key: /^notification_mailer\./)}

  validates_presence_of :version
  before_save :scrub_value
  #after_save :wear_out
  before_create :resolve_value_type

  def localize_model
    return unless is_model_localization?
    target_locale = version.localization.name
    hash = get_model_instance_hash
    if hash.nil?
      destroy
    else
      klass = hash[:klass]
      field = hash[:field]
      id = hash[:id]

      que = klass.find_by(id: id)

      I18n.locale = target_locale
      que.send "#{field}=", value
      que.save
    end
  end

  def original
    if is_model_localization?
      hash = get_model_instance_hash
      return 'Deprecated translation' if hash.nil?
      begin
        hash[:klass].find_by(id: hash[:id]).send hash[:field]
      rescue
        'Deprecated translation'
      end
    else
      I18n.t key
    end
  end

  def get_model_instance_hash
    return nil unless is_model_localization?
    tmp = key.split('.')
    {klass: tmp[0].gsub('_', '::').constantize, field: tmp[1].parameterize.underscore.to_sym, id: tmp[2]}
  rescue
    nil
  end

  def self.active
    tr_ids = []
    Localization.each do |l|
      tr_ids += active_ids_in l
    end
    Translation.where(:id.in => tr_ids).not_model_localizers
  end

  def self.active_ids_in(localization)
    approved_version_ids = localization.localization_versions.approved.distinct(:id)
    match = {"$match" => Translation.where(:version_id.in => approved_version_ids).selector}
    sort = {"$sort" => {"version_id" => -1}}
    group = {"$group" => {"_id" => "$key", "first" => {"$first" => "$_id"}}}
    Translation.collection.aggregate(match, sort, group).map {|g| g['first']}
  end

  def self.active_in(localization)
    Translation.where :id.in => active_ids_in(localization)
  end

  def self.all_translation_by_version(version)
    exist_in_version = version.translations
    keys_exists_in_version = exist_in_version.distinct(:key)
    other = Translation.all_in(version.localization).where :key.nin => keys_exists_in_version
    keys_in_other = other.distinct(:key)
    fallbacks = Translation.all_in(Localization.default).where :key.nin => (keys_exists_in_version + keys_in_other)
    Translation.any_of exist_in_version.selector, other.selector, fallbacks.selector
  end

  def self.all_in(localization)
    exist_in_locale = Translation.active_in(localization)
    original_locale = Localization.find_by name: I18n.locale
    fallbacks = Translation.active_in(original_locale).where :key.nin => exist_in_locale.distinct(:key)
    Translation.any_of(exist_in_locale.selector, fallbacks.selector)
  end

  def self.all_deleted_in(localization)
    version_ids = localization.localization_versions.distinct(:id)
    match = {"$match" => Translation.deleted.where(:version_id.in => version_ids).selector}
    sort = {"$sort" => {"version_id" => -1}}
    group = {"$group" => {"_id" => "$key", "first" => {"$first" => "$_id"}}}
    ids = Translation.collection.aggregate(match, sort, group).map {|g| g['first']}
    Translation.deleted.where :id.in => ids
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

      keys = Translation.where(:version_id.in => version_ids).distinct(:key)
      in_version = version.translations.where :key.in => keys

      match = {"$match" => Translation.where(:version_id.in => version_ids, :key.nin => in_version.distinct(:key)).selector}
      sort = {"$sort" => {"version_id" => -1}}
      group = {"$group" => {"_id" => "$key", "first" => {"$first" => "$_id"}}}
      dependent = Translation.where :id.in => (Translation.collection.aggregate(match, sort, group).map {|g| g['first']})
      Translation.any_of in_version.selector, dependent.selector
    end
  end

  def value
    value = super
    value.is_a?(String) && value_is_array ? value.split(',')  : value
  end

  def scrub_value
    self.value = Loofah.fragment(value).scrub!(:prune).to_s if value.is_a? String
  end


  private
  def resolve_value_type
    self.value_is_array = true if value.is_a? Array
    true
  end

  def wear_out
    version_ids = version.localization.localization_versions.where(:_id.lt => id).distinct(:id)
    Translation.actual.where(:id.ne => id, :key => key, :version_id.in => version_ids).update_all next_id: id
  end
end
