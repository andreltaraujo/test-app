module Disbursements
  class DisbursementsTask
    
		def self.execute	
			Merchant.where(disbursement_frequency: "WEEKLY").each do |merchant|
				start_date = merchant.live_on
				end_date = Date.parse('08 Feb 2023')
				weeks = (start_date..end_date).to_a.group_by { |date| [date.cweek, date.year] }
				merchant_end_week_day = merchant.live_on.wday == 0 ? 6 : merchant.live_on.wday - 1
					weeks.each do |(week_number, year), dates|
						merchant_week_end_day = dates.select { |date| date.wday == merchant_end_week_day }
						merchant_end_week_date = merchant_week_end_day.first
						if merchant_end_week_date
							merchant_start_week_date = merchant_end_week_date - 6
						else
							puts "No valid date found"
							next
						end
						merchant_week_day = dates.select { |date| date.wday == merchant.live_on.wday}
						disbursement_day = merchant_week_day.first
						if disbursement_day
							disbursement_day = disbursement_day
						else
							puts "No valid date found"
						end
						commissions_for_week = OrderCommission.joins(:order).where(orders: { merchant_reference: merchant.reference }).where(created_at: merchant_start_week_date.beginning_of_day..merchant_end_week_date.end_of_day)
						if commissions_for_week.any?
							disbursement_amounts = { order_fee_amount: 0, amount: 0 }
							commissions_for_week.each do |commission|
								debugger
								disbursement_amounts[:order_fee_amount] += commission.sequra_amount
								disbursement_amounts[:amount] += commission.merchant_amount
							end
							disbursement = nil
							begin
								Disbursement.transaction do
									disbursement = Disbursement.create!( 
									reference: SecureRandom.alphanumeric(13),	
									order_fee_amount: disbursement_amounts[:order_fee_amount],
										amount: disbursement_amounts[:merchant_amount],
										currency: 'EUR',
										created_at: disbursement_day
									)
									updated_associated_records = []
									commissions_for_week.each do |commission|
										commission.update(disbursement_id: disbursement.id)
										updated_associated_records << commission
										order = commission.order
										order.update(disbursement_id: disbursement.id, disbursement_reference: disbursement.reference)
										updated_associated_records << order
									end
								rescue ActiveRecord::RecordInvalid => e
									Rails.logger.error "[DisbursementsTask][Validation failed] #{e.message} #{e.backtrace}"
								rescue StandardError => e
									Rails.logger.error "[DisbursementsTask][error] #{e.message} #{e.backtrace}"
									Rails.logger.info "Disbursement created for #{updated_associated_records} for merchant #{merchant.reference}"
								end
							end
						else
							Rails.logger.info "No orders for week #{week_number} for merchant #{merchant.reference}"
						end
					end
				end
			end
		end
	end
