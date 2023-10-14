class OrderCommissionGenerator

	def execute(orders)
		orders = Array.wrap(orders)
		orders.each do |order|
			unless OrderCommission.where(order_id: order.id).empty?
				order_commissions = OrderCommission.where(order_id: order.id)
			else
				error_message = "[#{self.class.name}][Error: OrderCommission_ID: #{order.order_commission.id} already generated for Order_ID: #{order.id}]"
				Rails.logger.error(error_message)
				return nil
			end
		end
  end
end

# Path: app/services/commission_calculator.rb
#commissions = []
#commission = CommissionCalculator.new(order).calculate
#order_commission = OrderCommission.create(commission)
#commissions << order_commission