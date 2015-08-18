class Visit
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  embedded_in :visitable, polymorphic: true
end
