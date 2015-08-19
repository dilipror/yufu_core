class Order::Written::WorkReportSerializer < ActiveModel::Serializer
  attributes :id, :hours, :description, :file_file_name, :file_url

  def file_url
    object.file.url
  end
end
