namespace :skuvault_purchase_order_importer_agent do
  desc "Start the workers for skuvault_purchase_order_importer_agent"
  task start: :environment do
    Dir.mkdir("#{Rails.root}/lib/workers/purcharse_orders/logs") unless File.directory?("#{Rails.root}/lib/workers/purcharse_orders/logs")
    Dir.mkdir("#{Rails.root}/lib/tasks/logs") unless File.directory?("#{Rails.root}/lib/tasks/logs")
    skuvault_purchase_order_importer_agent_logger = Logger.new("#{File.dirname(__FILE__)}/logs/skuvault_purchase_order_importer_agent_rake.log", 'weekly')
    skuvault_purchase_order_importer_agent_logger.formatter = Logger::Formatter.new
    skuvault_purchase_order_importer_agent_pgrep_output = `pgrep -f skuvault_purchase_order_importer_agent.rb`
    if skuvault_purchase_order_importer_agent_pgrep_output.empty?
      skuvault_purchase_order_importer_agent_logger.info "Process is not running so lets start the process"
      puts "Process is not running so lets start the process"
      system("RAILS_ENV=development nohup bundle exec ruby #{Rails.root}/lib/workers/purcharse_orders/skuvault_purchase_order_importer_agent.rb >  #{Rails.root}/lib/workers/purcharse_orders/logs/skuvault_purchase_order_importer_agent_nohup.log 2>&1 &")
      puts 'Process started'
      skuvault_purchase_order_importer_agent_logger.info 'Process started'
    else
      puts "Process is Already running with PID #{skuvault_purchase_order_importer_agent_logger}"
    end
  end
end


namespace :skuvault_purchase_order_updater_agent do
  desc "Start the workers for skuvault_purchase_order_updater_agent"
  task start: :environment do
    Dir.mkdir("#{Rails.root}/lib/workers/purcharse_orders/logs") unless File.directory?("#{Rails.root}/lib/workers/purcharse_orders/logs")
    Dir.mkdir("#{Rails.root}/lib/tasks/logs") unless File.directory?("#{Rails.root}/lib/tasks/logs")
    skuvault_purchase_order_updater_agent_logger = Logger.new("#{File.dirname(__FILE__)}/logs/skuvault_purchase_order_updater_agent_rake.log", 'weekly')
    skuvault_purchase_order_updater_agent_logger.formatter = Logger::Formatter.new
    skuvault_purchase_order_updater_agent_pgrep_output = `pgrep -f skuvault_purchase_order_updater_agent.rb`
    if skuvault_purchase_order_updater_agent_pgrep_output.empty?
      skuvault_purchase_order_updater_agent_logger.info "Process is not running so lets start the process"
      puts "Process is not running so lets start the process"
      system("RAILS_ENV=development nohup bundle exec ruby #{Rails.root}/lib/workers/purcharse_orders/skuvault_purchase_order_updater_agent.rb >  #{Rails.root}/lib/workers/purcharse_orders/logs/skuvault_purchase_order_updater_agent_nohup.log 2>&1 &")
      puts 'Process started'
      skuvault_purchase_order_updater_agent_logger.info 'Process started'
    else
      puts "Process is Already running with PID #{skuvault_purchase_order_updater_agent_logger}"
    end
  end
end

namespace :purchase_order_processor_agent do
  desc "Start the workers for purchase_order_processor_agent"
  task start: :environment do
    Dir.mkdir("#{Rails.root}/lib/workers/purcharse_orders/logs") unless File.directory?("#{Rails.root}/lib/workers/purcharse_orders/logs")
    Dir.mkdir("#{Rails.root}/lib/tasks/logs") unless File.directory?("#{Rails.root}/lib/tasks/logs")
    purchase_order_processor_agent_logger = Logger.new("#{File.dirname(__FILE__)}/logs/purchase_order_processor_agent_rake.log", 'weekly')
    purchase_order_processor_agent_logger.formatter = Logger::Formatter.new
    purchase_order_processor_agent_pgrep_output = `pgrep -f purchase_order_processor_agent.rb`
    if purchase_order_processor_agent_pgrep_output.empty?
      purchase_order_processor_agent_logger.info "Process is not running so lets start the process"
      puts "Process is not running so lets start the process"
      system("RAILS_ENV=development nohup bundle exec ruby #{Rails.root}/lib/workers/purcharse_orders/purchase_order_processor_agent.rb >  #{Rails.root}/lib/workers/purcharse_orders/logs/purchase_order_processor_agent_nohup.log 2>&1 &")
      puts 'Process started'
      purchase_order_processor_agent_logger.info 'Process started'
    else
      puts "Process is Already running with PID #{purchase_order_processor_agent_logger}"
    end
  end
end

namespace :dealers_importer_data_agent do
  desc "Start the workers for dealers_importer_data_agent"
  task start: :environment do
    Dir.mkdir("#{Rails.root}/lib/workers/purcharse_orders/logs") unless File.directory?("#{Rails.root}/lib/workers/purcharse_orders/logs")
    Dir.mkdir("#{Rails.root}/lib/tasks/logs") unless File.directory?("#{Rails.root}/lib/tasks/logs")
    dealers_importer_data_agent_logger = Logger.new("#{File.dirname(__FILE__)}/logs/dealers_importer_data_agent_rake.log", 'weekly')
    dealers_importer_data_agent_logger.formatter = Logger::Formatter.new
    dealers_importer_data_agent_pgrep_output = `pgrep -f dealers_importer_data_agent.rb`
    if dealers_importer_data_agent_pgrep_output.empty?
      dealers_importer_data_agent_logger.info "Process is not running so lets start the process"
      puts "Process is not running so lets start the process"
      system("RAILS_ENV=development nohup bundle exec ruby #{Rails.root}/lib/workers/purcharse_orders/dealers_importer_data_agent.rb >  #{Rails.root}/lib/workers/purcharse_orders/logs/dealers_importer_data_agent_nohup.log 2>&1 &")
      puts 'Process started'
      dealers_importer_data_agent_logger.info 'Process started'
    else
      puts "Process is Already running with PID #{dealers_importer_data_agent_logger}"
    end
  end
end