class Device < ApplicationRecord
  has_many :readings, dependent: :destroy

  validates :uid, presence: true, uniqueness: true

  def total_count
    readings.sum(:count)
  end

  def latest_timestamp
    readings.maximum(:timestamp)
  end
end
