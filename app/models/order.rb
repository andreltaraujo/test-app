class Order < ApplicationRecord
  belongs_to :disbursement, optional: true
	belongs_to :merchant
	
	validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
	validates :merchant_reference, presence: true	
	monetize :amount_cents
end
