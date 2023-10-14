require 'rails_helper'

RSpec.describe OrderCommissionGenerator do
	describe '#execute' do
		let!(:order) { create(:order) }
		context 'When there is no order commission generated yet' do
			it 'creates a new order commission' do
				expect do
					OrderCommissionGenerator.new.execute(order)
				end.to change(OrderCommission, :count).by(1)
			end
		end
		
		context 'When there is already an order commission generated' do
			let!(:order_commission) { create(:order_commission, order_id: order.id) }
			it 'does not create a new order commission' do
				expect do
					OrderCommissionGenerator.new.execute(order)
				end.to_not change(OrderCommission, :count)
			end
		end
	end
end