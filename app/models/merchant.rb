class Merchant < ApplicationRecord
	has_many :orders

	monetize :minimum_monthly_fee_cents
end
