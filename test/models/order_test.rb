require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "order should be valid" do
		merchant = Merchant.create!(
			reference: "123",
			email: "merchant@example.com",
			live_on: Date.parse('01-10-2022'),
			disbursement_frequency: 'DAILY',
			minimum_monthly_fee_cents: 1500
		)
		order = Order.new(amount_cents: 1000, merchant_reference: merchant.reference, currency: 'EUR', merchant: merchant, created_at: DateTime.now)
		order.save

		assert order.valid?

		assert_equal merchant, order.merchant
		assert_respond_to order, :merchant
  end
end