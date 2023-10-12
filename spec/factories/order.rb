FactoryBot.define do
  factory :order do
		merchant_reference  { "roob_davis" }
		amount { 453.28 }
		currency { "EUR" }
		disbursement_reference { nil }
		disbursement_id { nil }
		association :merchant, factory: :merchant
		created_at { DateTime.new(2023, 1, 21) }
  end
end
