class CollectionString < ApplicationRecord
  belongs_to :collection

  validates :language, :title, presence: true
  # validates :title, uniqueness: true
end
