class OrderCommissionGeneratorWorker
  include Sidekiq::Worker

  def perform(order_id)
		Rails.logger.info("[#{self.class.name}][Starting generation...]")
		order = Order.find(order_id)
    OrderCommissionGenerator.new.execute(order)
    Rails.logger.info("[#{self.class.name}][Generation finished. ] #{Time.now.utc.to_s}")
  rescue StandardError => e
    Rails.logger.error("[#{self.class.name}][Error] #{e.message}")
    Rails.logger.error("[#{self.class.name}][Error] Backtrace: #{e.backtrace}")
  end
end
