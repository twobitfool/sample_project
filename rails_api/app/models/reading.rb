class Reading < ApplicationRecord
  belongs_to :device

  validates :timestamp, presence: true
  validates :count, presence: true
end
