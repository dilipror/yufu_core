# Manage emails on remote mysql server
module Virtual
  def self.table_name_prefix
    'virtual_'
  end

  def self.to_s
    I18n.t('modules.virtual')
  end
end
