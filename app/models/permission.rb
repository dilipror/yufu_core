class Permission
  include Mongoid::Document

  AVAILABLE_ACTIONS = %w(read create update destroy manage)

  field :name
  field :subject_class
  field :subject_id, type: Integer
  field :action
  field :description

  embedded_in :group
  embedded_in :user

  def self.all_models
    return @models if @models.present?
    base_path = Pathname.new "#{Rails.root}/app/models"
    @models = Dir[File.join(base_path, '**', '*.rb')].map do |full_path|
      contant = Pathname.new(full_path).relative_path_from(base_path).to_s.gsub!('.rb', '').camelize
      contant =~ /Concerns::.*/ ? next : contant
    end.compact
    @models << 'all'
  end

  validates_inclusion_of :action, in: AVAILABLE_ACTIONS
  validates_inclusion_of :subject_class, in: Permission.all_models
end
