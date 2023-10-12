FactoryBot.define do
  factory :disbursement do
		order_fee_amount { 98.00 }
		amount { 1000.00 }
		currency	{ 'EUR' }

		before(:create) do |disbursement|
			reference = Disbursement.new.send(:generate_reference)
			disbursement.reference = reference
		end
	end
end
