# frozen_string_literal: true

require "rounding"

class MembershipPricing
  def initialize(params = {})
    # Works with both the registration and renewal form params
    @params = params.transform_keys { |k|
      k.to_s
        .sub(/\Awaiting_/, "")
        .sub(/members_basket_complements_attributes/, "memberships_basket_complements_attributes")
    }.with_indifferent_access
    Rails.logger.debug "MembershipPricing: #{@params.inspect}"
    @min = 0
    @max = 0
  end

  def prices
    @prices ||= begin
      add(baskets_prices)
      add(baskets_price_extras)
      add(depot_prices)
      complements_prices.each { |prices| add(prices) }
      add(activity_participations_prices)

      [ @min, @max ].uniq
    end
  end

  def present?
    !simple_pricing? && prices.any?(&:positive?)
  end

  private

  def simple_pricing?
    Depot.visible.sum(:price).zero? &&
      BasketComplement.visible.sum(:price).zero? &&
      DeliveryCycle.visible.map(&:billable_deliveries_count).uniq.one? &&
      deliveries_counts.one? &&
      !Current.org.feature?("basket_price_extra") &&
      !@params[:activity_participations_demanded_annually]
  end

  def basket_size
    @basket_size ||= BasketSize.find_by(id: @params[:basket_size_id])
  end

  def baskets_prices
    return [ 0, 0 ] unless basket_size

    [
      deliveries_counts.min * basket_size.price,
      deliveries_counts.max * basket_size.price
    ]
  end

  def baskets_price_extras
    extra = @params[:basket_price_extra].to_f
    return [ 0, 0 ] if extra.zero?

    comp_prices = [ 0, 0 ]
    complements_prices.each { |p|
      comp_prices = comp_prices.zip(p.map(&:round_to_five_cents)).map(&:sum)
    }

    [
      deliveries_counts.min * calculate_price_extra(extra, basket_size, comp_prices.min / deliveries_counts.min, deliveries_counts.min),
      deliveries_counts.max * calculate_price_extra(extra, basket_size, comp_prices.max / deliveries_counts.max, deliveries_counts.max)
    ]
  end

  def calculate_price_extra(extra, basket_size, complements_price, deliveries_count)
    return 0 unless Current.org.feature?("basket_price_extra")
    return 0 unless basket_size

    Current.org.calculate_basket_price_extra(
      extra,
      basket_size.price,
      basket_size.id,
      complements_price,
      deliveries_count)
  end

  def complements_prices
    attrs = @params[:memberships_basket_complements_attributes].to_h
    return [ [ 0, 0 ] ] unless attrs.present?

    attrs.map { |_, attrs|
      complement_prices(attrs[:basket_complement_id], attrs[:quantity].to_i)
    }
  end

  def complement_prices(complement_id, quantity)
    complement = BasketComplement.find_by(id: complement_id)
    return [ 0, 0 ] unless complement
    return [ 0, 0 ] if quantity.zero?

    deliveries_counts = delivery_cycles.map { |dc|
      dc.billable_deliveries_count_for(complement)
    }.uniq
    [
      deliveries_counts.min * complement.price * quantity,
      deliveries_counts.max * complement.price * quantity
    ]
  end

  def activity_participations_prices
    return [ 0, 0 ] unless @params[:activity_participations_demanded_annually]
    return [ 0, 0 ] unless basket_size

    counts = delivery_cycles.map { |dc|
      fy = Delivery.last.fiscal_year
      m = Membership.new(
        started_on: fy.beginning_of_year,
        ended_on: fy.end_of_year,
        member: Member.new(salary_basket: false),
        basket_size: basket_size,
        delivery_cycle: dc,
        memberships_basket_complements_attributes: @params[:memberships_basket_complements_attributes].to_h,
        activity_participations_annual_price_change: nil)
      m.activity_participations_demanded_annually = m.activity_participations_demanded_annually_by_default
      default = ActivityParticipationDemanded.new(m).count
      m.activity_participations_demanded_annually = @params[:activity_participations_demanded_annually]
      demanded = ActivityParticipationDemanded.new(m).count
      -1 * (demanded - default)  * Current.org.activity_price
    }
    [ counts.min, counts.max ]
  end

  def depot_prices
    return [ 0, 0 ] unless depot

    [
      deliveries_counts.min * depot.price,
      deliveries_counts.max * depot.price
    ]
  end

  def deliveries_counts
    return [ 0 ] unless delivery_cycles.any?

    @deliveries_counts ||= delivery_cycles.map(&:billable_deliveries_count).flatten.uniq.sort
  end

  def delivery_cycles
    return [ delivery_cycle ] if delivery_cycle
    return [ basket_size.delivery_cycle ] if basket_size&.delivery_cycle

    @delivery_cycle_ids ||= depots.map(&:delivery_cycle_ids).flatten.uniq
    @delivery_cycles ||= DeliveryCycle.find(@delivery_cycle_ids).to_a
  end

  def delivery_cycle
    @delivery_cycle ||=
      DeliveryCycle.find_by(id: @params[:delivery_cycle_id])
  end

  def depots
    return [ depot ] if depot

    @depots ||= Depot.visible.includes(:delivery_cycles).to_a
  end

  def depot
    @depot ||= Depot.find_by(id: @params[:depot_id])
  end

  def add(prices)
    @min, @max =
      [ @min, @max ].zip(prices.map(&:round_to_five_cents)).map(&:sum)
  end
end
