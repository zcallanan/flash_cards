class DeckString < ApplicationRecord
  belongs_to :deck
  belongs_to :user
  has_many :user_logs
  accepts_nested_attributes_for :deck

  validates :deck, :language, :title, presence: true
end
