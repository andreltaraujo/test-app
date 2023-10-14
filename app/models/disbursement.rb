class Disbursement < ApplicationRecord
	has_many :orders
	has_many :order_commissions

	validates :reference, presence: true

	monetize :order_fee_amount_cents
	monetize :amount_cents

	before_create :generate_reference

	private

	def generate_reference
		self.reference = SecureRandom.alphanumeric(13)
	end
end
