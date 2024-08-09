# frozen_string_literal: true

class Liquid::ActivityDrop < Liquid::Drop
  def initialize(activity)
    @activity = activity
  end

  def title
    @activity.title
  end

  def description
    @activity.description
  end

  def date
    I18n.l(@activity.date)
  end

  def date_long
    I18n.l(@activity.date, format: :long)
  end

  def period
    @activity.period
  end

  def place
    @activity.place
  end

  def place_url
    @activity.place_url
  end

  def total_participants_count
    @activity.participants_count
  end

  def missing_participants_count
    @activity.missing_participants_count
  end
end
