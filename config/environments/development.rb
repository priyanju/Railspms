Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.

#  ENV["APP_URL"] = "http://15.207.212.223:4002"
#  ENV["APP_URL"] = "http://192.168.1.166:4901"
   ENV["APP_URL"] = "http://3.108.244.201:3004"
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=172800'
    }
  else
    config.action_controller.perform_caching = true

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.perform_caching = true
##########
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_options = {from: 'no-reply@example.com'}

#############

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
   :address => "smtp.gmail.com",
    :port => "587",
    :domain => "gmail.com",
    :user_name => "yantra1021@gmail.com",
    :password => "WelcomeYantra",
    :authentication => "plain",
#    :enable_starttls_auto => true
  }
    config.action_mailer.default_url_options = { :host => 'gmail.com' }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log
  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load
  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end


