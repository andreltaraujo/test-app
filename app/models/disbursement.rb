class Disbursement < ApplicationRecord
	has_many :orders

	monetize :order_fee_amount_cents
	monetize :amount_cents
end
