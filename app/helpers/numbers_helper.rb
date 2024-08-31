# frozen_string_literal: true

module NumbersHelper
  include ActiveSupport::NumberHelper

  def currency_symbol
    case Current.org.currency_code
    when "EUR"; "€"
    else
      Current.org.currency_code
    end
  end

  def cur(amount, unit: true, **options)
    options[:unit] = unit ? currency_symbol : ""
    options[:format] ||=
      case Current.org.currency_code
      when "EUR"; "%n %u"
      when "CHF"; "%u %n"
      end
    unless unit
      options[:negative_format] ||= "-%n"
    end
    number_to_currency(amount, **options)
  end

  def kg(amount)
    number = number_to_rounded(amount,
      precision: 2,
      strip_insignificant_zeros: true)
    "#{sprintf("%.1f", number)} kg"
  end

  def _number_to_percentage(number, **options)
    txt = number_to_percentage(number, **options)
    if number.positive?
      "+#{txt}"
    else
      txt
    end
  end
end
