class OrderCommissionGenerator

	def execute(order_id)
		order = Order.find_by(id: order_id)
		if OrderCommission.where(order_id: order.id).empty?
			commission = CommissionCalculator.new(order).calculate
			OrderCommission.create(commission)
		else
			Rails.logger.error("[#{self.class.name}][Error: OrderCommission_ID: #{order.order_commission.id} already generated for Order_ID: #{order.id}]")
		end
  end
end
