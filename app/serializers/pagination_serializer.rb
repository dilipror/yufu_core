class PaginationSerializer < ActiveModel::ArraySerializer
  def initialize(object, options={})
    meta_key = options[:meta_key] || :meta
    options[meta_key] ||= {}
    options[meta_key] = {
        current_page: object.current_page,
        total_pages:  object.total_pages
    }
    super(object, options)
  end
end