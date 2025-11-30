require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Render provides SSL termination automatically
  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # Render handles SSL certificates automatically
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Use memory cache store for single-database deployment
  config.cache_store = :memory_store

  # Use async queue adapter (in-process) for single-database deployment
  config.active_job.queue_adapter = :async

  # Configure ActionMailer for production
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: ENV.fetch("RENDER_EXTERNAL_HOSTNAME", "example.com"), protocol: "https" }

  # SMTP configuration using environment variables
  # Works with SendGrid, Postmark, Mailgun, AWS SES, etc.
  # Set these environment variables in Render dashboard:
  # - SMTP_ADDRESS (e.g., smtp.sendgrid.net)
  # - SMTP_PORT (e.g., 587)
  # - SMTP_USERNAME (your SMTP username)
  # - SMTP_PASSWORD (your SMTP password)
  # - SMTP_DOMAIN (optional, your domain)
  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_ADDRESS"),
      port: ENV.fetch("SMTP_PORT", 587),
      user_name: ENV.fetch("SMTP_USERNAME"),
      password: ENV.fetch("SMTP_PASSWORD"),
      domain: ENV.fetch("SMTP_DOMAIN", "golfcoachapp.com"),
      authentication: :plain,
      enable_starttls_auto: true
    }
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # Render automatically provides RENDER_EXTERNAL_HOSTNAME
  # Allow Render's default domain (.onrender.com) and any custom domains
  config.hosts = [
    ".onrender.com",                              # All Render domains
    ENV["RENDER_EXTERNAL_HOSTNAME"]               # Your specific Render URL
  ].compact

  # If you have a custom domain, add it here:
  # config.hosts << "yourdomain.com"
  # config.hosts << "www.yourdomain.com"

  # Skip DNS rebinding protection for the default health check endpoint.
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
