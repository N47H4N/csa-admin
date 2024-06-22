# frozen_string_literal: true

module Scheduled
  class NotifierHourlyJob < BaseJob
    def perform
      Notifier.send_all_hourly
    end
  end
end
