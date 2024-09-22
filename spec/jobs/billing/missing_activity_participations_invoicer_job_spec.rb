# frozen_string_literal: true

require "rails_helper"

describe Billing::MissingActivityParticipationsInvoicerJob do
  before { Current.org.update!(activity_price: 90, trial_baskets_count: 0) }

  specify "noop if no activty price" do
    Current.org.update!(activity_price: 0)

    membership = create(:membership, activity_participations_demanded_annually: 2)

    expect { described_class.perform_later(membership) }
      .not_to change(Invoice, :count)
  end

  specify "noop if no missing activity participations" do
    membership = create(:membership, activity_participations_demanded_annually: 0)

    expect { described_class.perform_later(membership) }
      .not_to change(Invoice, :count)
  end

  specify "create invoice and send invoice", sidekiq: :inline do
    membership = create(:membership, activity_participations_demanded_annually: 2)

    expect { described_class.perform_later(membership) }
      .to change(Invoice, :count).by(1)
      .and change { membership.reload.activity_participations_missing }.to(0)
      .and change { InvoiceMailer.deliveries.size }.by(1)

    invoice = Invoice.last
    expect(invoice).to have_attributes(
      member_id: membership.member_id,
      date: Date.today,
      missing_activity_participations_count: 2,
      missing_activity_participations_fiscal_year: membership.fiscal_year,
      entity_type: "ActivityParticipation",
      entity_id: nil,
      amount: 2 * 90)
    expect(invoice).to be_sent
  end

  specify "create invoice for previous year membership", sidekiq: :inline do
    Current.org.update!(fiscal_year_start_month: 5)
    membership = travel_to "2021-01-06" do
      create(:membership, activity_participations_demanded_annually: 2)
    end

    expect { described_class.perform_later(membership) }
      .to change(Invoice, :count).by(1)

    invoice = Invoice.last
    expect(invoice).to have_attributes(
      member_id: membership.member_id,
      date: Date.today,
      missing_activity_participations_fiscal_year: Current.org.fiscal_year_for(2020),
      entity_type: "ActivityParticipation",
      entity_id: nil)
    expect(invoice).to be_sent
  end
end
