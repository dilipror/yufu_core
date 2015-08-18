module Approvable
  extend ActiveSupport::Concern

  included do
    field :is_approved, type: Mongoid::Boolean, default: false

    scope :not_approved, -> {where is_approved: false}
    scope :approved,     -> {where is_approved: true}
  end
  
  def approve
    self.update is_approved: true
  end

  def approve!
    self.update! is_approved: true
  end
end