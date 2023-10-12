FactoryBot.define do
  factory :order_commission do
    order_amount { 25.43 }
    sequra_amount { 0.25 }
    merchant_amount { 25.18 }
    fee_percentage { 0.01 }
    order_date { DateTime.new(2022, 10, 22)}
		association	:order
    disbursement { nil }

  end
end
