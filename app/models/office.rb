class Office
  include Mongoid::Document
  include Mongoid::Timestamps
  include Accountable

  field :head, type: Mongoid::Boolean, default: false

  belongs_to :city

  validates_presence_of :city, unless: :head

  def name
    persisted? ? "Office in #{city.name}" : 'New Office'
  end

  def self.head
    where(head: true).first || Office.create(head: true)
  end
end
