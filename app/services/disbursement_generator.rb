class DisbursementGenerator

	def execute
		Rails.logger.error "[DailyDisbursementsGeneration][Process Started] Processing date: #{Date.today} - Reference date: #{Date.yesterday}"
		daily_merchants_to_process = merchants_daily

		reports = []

		daily_merchants_to_process.each do |daily_merchant|
			day_date = Date.yesterday
			day_orders_to_process = fetch_day_orders(daily_merchant, day_date)
			if day_orders_to_process.any?
				debugger
				# Extract required data from day_orders_to_process
				orders_data = day_orders_to_process.map do |order|
					{
						id: order.id,
						merchant_reference: order.merchant_reference,
						amount_cents: order.amount_cents
					}
				end
				Rails.logger.info "[DisbursementsDailyTask][Orders to process] #{orders_data}"

				generated_day_commissions = OrderCommissionGenerator.new.execute(day_orders_to_process)
				if generated_day_commissions.present?

					generated_day_commissions_data = generated_day_commissions.map do |commission|
						{
							id: commission.id,
							order_amount_cents: commission.order_amount_cents,
							sequra_amount_cents: commission.sequra_amount_cents,
							merchant_amount_cents: commission.merchant_amount_cents,
							fee_percentage: commission.fee_percentage,
							order_date: commission.order_date,
							order_id: commission.order_id,
							disbursement_id: commission.disbursement_id,
							created_at: commission.created_at
						}
					end
					Rails.logger.info "[DisbursementsDailyTask][Commissions generated] #{generated_day_commissions_data}"

					calculated_day_disbursement = DisbursementCalculator.new(generated_day_commissions).calculate

					calculated_day_disbursement_data = {
						order_fee_amount: calculated_day_disbursement.order_fee_amount,
						amount: calculated_day_disbursement.amount
					}
					Rails.logger.info "[DisbursementsDailyTask][Disbursement calculated] #{calculated_day_disbursement_data}"

					begin
						Disbursement.transaction do
							created_day_disbursement = Disbursement.create(calculated_day_disbursement)

							created_day_disbursement_data = {
								reference: created_day_disbursement.reference,
								order_fee_amount_cents: created_day_disbursement.order_fee_amount_cents,
								amount_cents: created_day_disbursement.amount_cents,
								currency: created_day_disbursement.currency,
								created_at: created_day_disbursement.created_at
							}
							Rails.logger.info "[DisbursementsDailyTask][Disbursement created] #{created_day_disbursement_data}"

							merchant_report = {
								merchant_reference: daily_merchant.reference,
								day_date: day_date,
								day_orders: orders_data,
								generated_day_commissions: generated_day_commissions_data,
								calculated_day_disbursement: calculated_day_disbursement_data,
								created_day_disbursement: created_day_disbursement_data
							}

							reports << merchant_report

							report_data = {
								merchant_reference: daily_merchant.reference,
								day_date: day_date,
								day_orders_to_process: day_orders_to_process.map { |order| order.attributes },
								generated_day_commissions: generated_day_commissions.map { |commission| commission.attributes },
								calculated_day_disbursement: calculated_day_disbursement.attributes,
								created_day_disbursement: created_day_disbursement.attributes
							}

							report_directory = "tmp/reports"
							FileUtils.mkdir_p(report_directory) unless File.directory?(report_directory)
							file_path = File.join(report_directory, "daily_merchant_report_#{daily_merchant.reference}.json")

							report_json = report_data.to_json

							File.open(file_path, "w") do |file|
								file.puts(report_json)
							end

							updated_disbursed_day_commissions = []
							day_orders_to_process.each do |day_commission|
								day_commission.update(disbursement_id: created_disbursement.id)
								updated_disbursed_day_commissions << day_commission.id
								order = day_commission.order
								order.update(disbursement_id: created_day_disbursement.id, disbursement_reference: created_day_disbursement.reference)
								updated_disbursed_day_commissions << order.id
								Rails.logger.info "Day Disbursement created for #{updated_disbursed_day_commissions} for daily merchant #{daily_merchant.reference}"
							end
						end
					rescue ActiveRecord::RecordInvalid => invalid
						Rails.logger.error "[DisbursementsDailyTask][Validation failed] #{invalid.message} #{invalid.backtrace}"
						Rails.logger.info "Day Disbursement created for #{updated_disbursed_day_commissions} for daily merchant #{daily_merchant.reference}"
					rescue StandardError => e
						Rails.logger.error "[DisbursementsDailyTask][error] #{e.message} #{e.backtrace}"
					end
				else
					Rails.logger.info "[DisbursementsDailyTask][Order commissions wasn't generated] for daily merchant #{daily_merchant.reference}"
				end
			else
				Rails.logger.info "[DisbursementsDailyTask][No order commissions to process] for daily merchant #{daily_merchant.reference}"
			end
			Rails.logger.error "[DailyDisbursementsGeneration][Process Finished] Processing date: #{Date.today} - Reference date: #{Date.yesterday}"
		end

		Rails.logger.error "[WeeklyDisbursementsGeneration][Process Started] Processing date: #{Date.today} - Reference date: #{Date.today - 6.days}-#{Date.yesterday}"
		weekly_merchants_to_process = merchants_weekly_today
		weekly_merchants_to_process.each do |weekly_merchant|
			week_dates = week_disbursements_dates(weekly_merchant)
			week_orders_to_process = fetch_week_orders(weekly_merchant, week_dates)
			if week_orders_to_process.any?
				generated_week_commissions = OrderCommissionGenerator.new.execute(week_orders_to_process)
				if generated_week_commissions.present?
					calculated_week_disbursement = DisbursementCalculator.new(generated_week_commissions).calculate
					begin
						Disbursement.transaction do
							created_week_disbursement = Disbursement.create(calculated_week_disbursement)

							report_data = {
								merchant_reference: weekly_merchant.reference,
								week_dates: week_dates,
								week_orders_to_process: week_orders_to_process.map { |order| order.attributes },
								generated_week_commissions: generated_week_commissions.map { |commission| commission.attributes },
								calculated_week_disbursement: calculated_week_disbursement.attributes,
								created_week_disbursement: created_week_disbursement.attributes
							}

							report_directory = "tmp/reports"
							FileUtils.mkdir_p(report_directory) unless File.directory?(report_directory)

							file_path = File.join(report_directory, "weekly_merchant_report_#{weekly_merchant.reference}.json")

							report_json = report_data.to_json

							File.open(file_path, "w") do |file|
								file.puts(report_json)
							end

							updated_disbursed_week_commissions = []
							week_orders_to_process.each do |commission|
								commission.update(disbursement_id: created_week_disbursement.id)
								updated_disbursed_week_commissions << commission.id
								order = commission.order
								order.update(disbursement_id: created_week_disbursement.id, disbursement_reference: created_week_disbursement.reference)
								updated_disbursed_week_commissions << order.id
								Rails.logger.info "Disbursement created for #{updated_disbursed_week_commissions} for weekly merchant #{weekly_merchant.reference}"
							end
						end
					rescue ActiveRecord::RecordInvalid => invalid
						Rails.logger.error "[DisbursementsWeeklyTask][Validation failed] #{invalid.message} #{invalid.backtrace}"
						Rails.logger.info "Week Disbursement created for #{updated_disbursed_week_commissions} for weekly merchant #{weekly_merchant.reference}"
					rescue StandardError => e
						Rails.logger.error "[DisbursementsWeeklyTask][error] #{e.message} #{e.backtrace}"
					end
				else
					Rails.logger.info "[DisbursementsWeeklyTask][Order commissions wasn't generated] for weekly merchant #{weekly_merchant.reference}"
				end
			else
				Rails.logger.info "[DisbursementsWeeklyTask][No order commissions to process] for weekly merchant #{weekly_merchant.reference}"
			end
		end
	end
	Rails.logger.error "[WeeklyDisbursementsGeneration][Process Started] Processing date: #{Date.today} - Reference date: #{Date.today - 6.days}-#{Date.yesterday}"

	def week_disbursements_dates(weekly_merchant)
		current_date = Date.today
		current_week_day = Date.today.wday
		if weekly_merchant.live_on.wday == current_week_day # Make sure the eligible weekly merchant live_on day is the same as today, even it was checked and selected before
			week_dates = {
				merchant_week_start_date: current_date - 6.days,
				merchant_week_end_date: current_date - 1.day
			}		
		else
			Rails.logger.info("[#{self.class.name}] nothing to process #{current_date}")
			return nil
		end
	end

	def merchants_daily
		Merchant.daily_eligible_merchants
	end

	def merchants_weekly_today
		Merchant.weekly_eligible_merchants		
	end
	def fetch_day_orders(daily_merchant, day_date)
		Order.daily_disbursements(daily_merchant.reference, day_date)
	end

	def fetch_week_orders(weekly_merchant, week_dates)
		Order.weekly_disbursements(weekly_merchant.reference, week_dates[:merchant_week_start_date], week_dates[:merchant_week_end_date])
	end
end