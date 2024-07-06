# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = [ :active_support_logger ]
  config.metrics.enabled = true
  config.traces_sample_rate = ENV["SENTRY_TRACES_SAMPLE_RATE"]&.to_f || 0.1
  config.enabled_environments = %w[production]
end
