class Order < ApplicationRecord
  VALUE_FOR_FEE_100 = 4999
	VALUES_FOR_FEE_095 = (5000..29999)
	VALUE_FOR_FEE_085 = 30000
	
	belongs_to :disbursement, optional: true
	belongs_to :merchant
	has_one :order_commission, dependent: :destroy
	
	validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
	validates :merchant_reference, presence: true	
	
	monetize :amount_cents
	
	scope :with_fee_100, -> { where('amount <= ?', VALUE_FOR_FEE_100) }
	scope :with_fee_095, -> { where(amount:  VALUES_FOR_FEE_095) } 
	scope :with_fee_085, -> { where('amount >= ?', VALUE_FOR_FEE_085) }

	scope :with_fee_100_by_merchant, ->(merchant_reference) { where(merchant_reference: merchant_reference).where('amount <= ?', VALUE_FOR_FEE_100) }
	scope :with_fee_095_by_merchant, ->(merchant_reference) { where(merchant_reference: merchant_reference).where(amount:  VALUES_FOR_FEE_095) } 
	scope :with_fee_085_by_merchant, ->(merchant_reference) { where(merchant_reference: merchant_reference).where('amount >= ?', VALUE_FOR_FEE_085) }
	
end
