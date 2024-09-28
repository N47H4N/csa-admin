# frozen_string_literal: true

require "rails_helper"

describe MembershipPricing do
  before do
    create(:basket_size, id: 1, price: 10)
    create(:basket_size, id: 2, price: 15)
  end

  def pricing(params = {})
    MembershipPricing.new(params)
  end

  specify "with no params" do
    expect(pricing.prices).to eq [ 0 ]
  end

  describe "member creation form" do
    specify "simple pricing" do
      create_deliveries(3)
      create(:depot, id: 1)

      expect(pricing).not_to be_present

      pricing = pricing(waiting_depot_id: 1)
      expect(pricing).not_to be_present
    end

    specify "with depot price" do
      create_deliveries(3)
      create(:depot, id: 1, price: 1)
      create(:depot, id: 2, price: 2)

      pricing = pricing(waiting_basket_size_id: 1)
      expect(pricing.prices).to eq [ 3 * 10 ]

      pricing = pricing(waiting_basket_size_id: 2)
      expect(pricing.prices).to eq [ 3 * 15 ]

      pricing = pricing(waiting_depot_id: 1)
      expect(pricing.prices).to eq [ 3 * 1 ]

      pricing = pricing(waiting_depot_id: 2)
      expect(pricing.prices).to eq [ 3 * 2 ]

      pricing = pricing(waiting_basket_size_id: 1, waiting_depot_id: 1)
      expect(pricing.prices).to eq [ 3 * (10 + 1) ]

      pricing = pricing(waiting_basket_size_id: 1, waiting_depot_id: 2)
      expect(pricing.prices).to eq [ 3 * (10 + 2) ]

      pricing = pricing(waiting_basket_size_id: 2, waiting_depot_id: 2)
      expect(pricing.prices).to eq [ 3 * (15 + 2) ]
    end

    specify "with price_extra" do
      Current.org.update! features: [ "basket_price_extra" ]
      create_deliveries(3)
      create(:depot)

      pricing = pricing(waiting_basket_size_id: 1, waiting_basket_price_extra: "2")
      expect(pricing.prices).to eq [ 3 * (10 + 2) ]
    end

    specify "with multiple delivery cycles" do
      create_deliveries(5)
      depot = create(:depot, id: 1)
      create(:depot, id: 2)

      create(:delivery_cycle, id: 2, results: :odd, depots: [ depot ])
      create(:delivery_cycle, id: 3, results: :all, depots: Depot.all)

      pricing = pricing(waiting_basket_size_id: 1)
      expect(pricing.prices).to eq [ 3 * 10, 5 * 10 ]

      pricing = pricing(waiting_basket_size_id: 1, waiting_depot_id: 2)
      expect(pricing.prices).to eq [ 5 * 10 ]

      pricing = pricing(
        waiting_basket_size_id: 1,
        waiting_depot_id: 1,
        waiting_delivery_cycle_id: 2)
      expect(pricing.prices).to eq [ 3 * 10 ]
    end

    specify "with multiple delivery cycles (absences included)" do
      create_deliveries(5)
      depot = create(:depot, id: 1)
      create(:depot, id: 2)

      create(:delivery_cycle, id: 2, absences_included_annually: 0)
      create(:delivery_cycle, id: 3, absences_included_annually: 2)

      pricing = pricing(waiting_basket_size_id: 1)
      expect(pricing.prices).to eq [ 3 * 10, 5 * 10 ]

      pricing = pricing(waiting_basket_size_id: 1, waiting_depot_id: 2)
      expect(pricing.prices).to eq [ 3 * 10, 5 * 10 ]

      pricing = pricing(
        waiting_basket_size_id: 1,
        waiting_depot_id: 1,
        waiting_delivery_cycle_id: 3)
      expect(pricing.prices).to eq [ 3 * 10 ]
    end

    specify "with multiple delivery cycles (absences included) and complements" do
      create_deliveries(4)
      depot = create(:depot, id: 1)
      create(:depot, id: 2)

      create(:basket_complement,
        id: 1,
        price: 3,
        delivery_ids: Delivery.all.pluck(:id))
      create(:basket_complement,
        id: 2,
        price: 4,
        delivery_ids: Delivery.limit(2).pluck(:id))

      create(:delivery_cycle, id: 2, absences_included_annually: 0)
      create(:delivery_cycle, id: 3, absences_included_annually: 2)

      pricing = pricing(members_basket_complements_attributes: {
        "0" => { basket_complement_id: 1, quantity: 1 }
      })
      expect(pricing.prices).to eq [ 2 * 3, 4 * 3 ]

      pricing = pricing(
        waiting_delivery_cycle_id: 2,
        members_basket_complements_attributes: {
          "0" => { basket_complement_id: 1, quantity: 1 }
        })
      expect(pricing.prices).to eq [ 4 * 3 ]

      pricing = pricing(
        waiting_delivery_cycle_id: 3,
        members_basket_complements_attributes: {
          "0" => { basket_complement_id: 1, quantity: 1 }
        })
      expect(pricing.prices).to eq [ 2 * 3 ]
    end

    specify "complements pricing" do
      create_deliveries(3)
      create(:depot, id: 1)

      create(:basket_complement,
        id: 1,
        price: 3,
        delivery_ids: Delivery.all.pluck(:id))
      create(:basket_complement,
        id: 2,
        price: 4,
        delivery_ids: Delivery.limit(2).pluck(:id))

      pricing = pricing(members_basket_complements_attributes: {
        "0" => { basket_complement_id: 1, quantity: 1 }
      })
      expect(pricing.prices).to eq [ 3 * 3 ]

      pricing = pricing(members_basket_complements_attributes: {
        "0" => { basket_complement_id: 1, quantity: 2 }
      })
      expect(pricing.prices).to eq [ 2 * 3 * 3 ]

      pricing = pricing(members_basket_complements_attributes: {
        "0" => { basket_complement_id: 2, quantity: 1 }
      })
      expect(pricing.prices).to eq [ 2 * 4 ]

      create(:delivery_cycle, id: 2, results: :odd, depots: Depot.all)
      create(:delivery_cycle, id: 3, results: :all, depots: Depot.all)

      pricing = pricing(members_basket_complements_attributes: {
        "0" => { basket_complement_id: 1, quantity: 1 }
      })
      expect(pricing.prices).to eq [ 2 * 3, 3 * 3 ]

      pricing = pricing(
        waiting_delivery_cycle_id: 2,
        members_basket_complements_attributes: {
          "0" => { basket_complement_id: 1, quantity: 1 }
        })
      expect(pricing.prices).to eq [ 2 * 3 ]
    end

    specify "with activity_participations_demanded_annually" do
      Current.org.update!(
        activity_participations_form_min: 0,
        activity_participations_form_max: 10,
        activity_price: 5)
      create_deliveries(4)
      create(:depot)

      BasketSize.find(1).update!(activity_participations_demanded_annually: 2)
      create(:basket_complement,
        id: 1,
        price: 2,
        activity_participations_demanded_annually: 1,
        delivery_ids: Delivery.all.pluck(:id))

      pricing = pricing(
        waiting_basket_size_id: 1,
        members_basket_complements_attributes: {
          "0" => { basket_complement_id: 1, quantity: 1 }
        })
      expect(pricing.prices).to eq [ 4 * (10 + 2) ]

      pricing = pricing(
        waiting_basket_size_id: 1,
        members_basket_complements_attributes: {
          "0" => { basket_complement_id: 1, quantity: 1 }
        },
        waiting_activity_participations_demanded_annually: 5)
      expect(pricing.prices).to eq [ 4 * (10 + 2) - 2 * 5 ]

      pricing = pricing(
        waiting_basket_size_id: 1,
        members_basket_complements_attributes: {
          "0" => { basket_complement_id: 1, quantity: 1 }
        },
        waiting_activity_participations_demanded_annually: 0)
      expect(pricing.prices).to eq [ 4 * (10 + 2) + 3 * 5 ]
    end
  end

  describe "membership renewal form" do
    specify "simple pricing" do
      create_deliveries(3)
      create(:depot, id: 1)

      expect(pricing).not_to be_present

      pricing = pricing(depot_id: 1)
      expect(pricing).not_to be_present
    end

    specify "with depot price" do
      create_deliveries(3)
      create(:depot, id: 1, price: 1)
      create(:depot, id: 2, price: 2)

      pricing = pricing(basket_size_id: 1)
      expect(pricing.prices).to eq [ 3 * 10 ]

      pricing = pricing(basket_size_id: 2)
      expect(pricing.prices).to eq [ 3 * 15 ]

      pricing = pricing(depot_id: 1)
      expect(pricing.prices).to eq [ 3 * 1 ]

      pricing = pricing(depot_id: 2)
      expect(pricing.prices).to eq [ 3 * 2 ]

      pricing = pricing(basket_size_id: 1, depot_id: 1)
      expect(pricing.prices).to eq [ 3 * (10 + 1) ]

      pricing = pricing(basket_size_id: 1, depot_id: 2)
      expect(pricing.prices).to eq [ 3 * (10 + 2) ]

      pricing = pricing(basket_size_id: 2, depot_id: 2)
      expect(pricing.prices).to eq [ 3 * (15 + 2) ]
    end

    specify "with price_extra" do
      Current.org.update! features: [ "basket_price_extra" ]
      create_deliveries(3)
      create(:depot)

      pricing = pricing(basket_size_id: 1, basket_price_extra: "2")
      expect(pricing.prices).to eq [ 3 * (10 + 2) ]
    end

    specify "with multiple delivery cycles" do
      create_deliveries(5)
      depot = create(:depot, id: 1)
      create(:depot, id: 2)

      create(:delivery_cycle, id: 2, results: :odd, depots: [ depot ])
      create(:delivery_cycle, id: 3, results: :all, depots: Depot.all)

      pricing = pricing(basket_size_id: 1)
      expect(pricing.prices).to eq [ 3 * 10, 5 * 10 ]

      pricing = pricing(basket_size_id: 1, depot_id: 2)
      expect(pricing.prices).to eq [ 5 * 10 ]

      pricing = pricing(
        basket_size_id: 1,
        depot_id: 1,
        delivery_cycle_id: 2)
      expect(pricing.prices).to eq [ 3 * 10 ]
    end

    specify "with multiple delivery cycles (absences included)" do
      create_deliveries(5)
      depot = create(:depot, id: 1)
      create(:depot, id: 2)

      create(:delivery_cycle, id: 2, absences_included_annually: 0)
      create(:delivery_cycle, id: 3, absences_included_annually: 2)

      pricing = pricing(basket_size_id: 1)
      expect(pricing.prices).to eq [ 3 * 10, 5 * 10 ]

      pricing = pricing(basket_size_id: 1, depot_id: 2)
      expect(pricing.prices).to eq [ 3 * 10, 5 * 10 ]

      pricing = pricing(
        basket_size_id: 1,
        depot_id: 1,
        delivery_cycle_id: 3)
      expect(pricing.prices).to eq [ 3 * 10 ]
    end

    specify "with multiple delivery cycles (absences included) and complements" do
      create_deliveries(4)
      depot = create(:depot, id: 1)
      create(:depot, id: 2)

      create(:basket_complement,
        id: 1,
        price: 3,
        delivery_ids: Delivery.all.pluck(:id))
      create(:basket_complement,
        id: 2,
        price: 4,
        delivery_ids: Delivery.limit(2).pluck(:id))

      create(:delivery_cycle, id: 2, absences_included_annually: 0)
      create(:delivery_cycle, id: 3, absences_included_annually: 2)

      pricing = pricing(memberships_basket_complements_attributes: {
        "0" => { basket_complement_id: 1, quantity: 1 }
      })
      expect(pricing.prices).to eq [ 2 * 3, 4 * 3 ]

      pricing = pricing(
        delivery_cycle_id: 2,
        memberships_basket_complements_attributes: {
          "0" => { basket_complement_id: 1, quantity: 1 }
        })
      expect(pricing.prices).to eq [ 4 * 3 ]

      pricing = pricing(
        delivery_cycle_id: 3,
        memberships_basket_complements_attributes: {
          "0" => { basket_complement_id: 1, quantity: 1 }
        })
      expect(pricing.prices).to eq [ 2 * 3 ]
    end

    specify "complements pricing" do
      create_deliveries(3)
      create(:depot, id: 1)

      create(:basket_complement,
        id: 1,
        price: 3,
        delivery_ids: Delivery.all.pluck(:id))
      create(:basket_complement,
        id: 2,
        price: 4,
        delivery_ids: Delivery.limit(2).pluck(:id))

      pricing = pricing(memberships_basket_complements_attributes: {
        "0" => { basket_complement_id: 1, quantity: 1 }
      })
      expect(pricing.prices).to eq [ 3 * 3 ]

      pricing = pricing(memberships_basket_complements_attributes: {
        "0" => { basket_complement_id: 1, quantity: 2 }
      })
      expect(pricing.prices).to eq [ 2 * 3 * 3 ]

      pricing = pricing(memberships_basket_complements_attributes: {
        "0" => { basket_complement_id: 2, quantity: 1 }
      })
      expect(pricing.prices).to eq [ 2 * 4 ]

      create(:delivery_cycle, id: 2, results: :odd, depots: Depot.all)
      create(:delivery_cycle, id: 3, results: :all, depots: Depot.all)

      pricing = pricing(memberships_basket_complements_attributes: {
        "0" => { basket_complement_id: 1, quantity: 1 }
      })
      expect(pricing.prices).to eq [ 2 * 3, 3 * 3 ]

      pricing = pricing(
        delivery_cycle_id: 2,
        memberships_basket_complements_attributes: {
          "0" => { basket_complement_id: 1, quantity: 1 }
        })
      expect(pricing.prices).to eq [ 2 * 3 ]
    end

    specify "with activity_participations_demanded_annually" do
      Current.org.update!(
        activity_participations_form_min: 0,
        activity_participations_form_max: 10,
        activity_price: 5)
      create_deliveries(4)
      create(:depot)

      BasketSize.find(1).update!(activity_participations_demanded_annually: 2)
      create(:basket_complement,
        id: 1,
        price: 2,
        activity_participations_demanded_annually: 1,
        delivery_ids: Delivery.all.pluck(:id))

      pricing = pricing(
        basket_size_id: 1,
        memberships_basket_complements_attributes: {
          "0" => { basket_complement_id: 1, quantity: 1 }
        })
      expect(pricing.prices).to eq [ 4 * (10 + 2) ]

      pricing = pricing(
        basket_size_id: 1,
        memberships_basket_complements_attributes: {
          "0" => { basket_complement_id: 1, quantity: 1 }
        },
        activity_participations_demanded_annually: 5)
      expect(pricing.prices).to eq [ 4 * (10 + 2) - 2 * 5 ]

      pricing = pricing(
        basket_size_id: 1,
        memberships_basket_complements_attributes: {
          "0" => { basket_complement_id: 1, quantity: 1 }
        },
        activity_participations_demanded_annually: 0)
      expect(pricing.prices).to eq [ 4 * (10 + 2) + 3 * 5 ]
    end
  end
end
