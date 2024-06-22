# frozen_string_literal: true

require "rails_helper"

describe Member do
  describe "validations" do
    it "requires address, city, zip, country_code on creation" do
      member = Member.new(
        address: nil,
        city: nil,
        zip: nil)
      member.country_code = nil
      expect(member).not_to have_valid(:address)
      expect(member).not_to have_valid(:city)
      expect(member).not_to have_valid(:zip)
      expect(member).not_to have_valid(:country_code)
    end

    it "does not require address, city, zip when inactive" do
      member = create(:member, :inactive,
        address: nil,
        city: nil,
        zip: nil,
        country_code: nil)
      expect(member).to be_valid
    end

    it "does require address, city, zip on update" do
      member = create(:member)
      member.attributes = {
        address: nil,
        city: nil,
        zip: nil,
        country_code: nil
      }
      expect(member).not_to have_valid(:zip)
      expect(member).not_to have_valid(:city)
      expect(member).not_to have_valid(:address)
      expect(member).not_to have_valid(:country_code)
    end

    it "sets first ACP billing_year_divisions by default" do
      Current.acp.billing_year_divisions = [ 4, 12 ]
      member = create(:member, :waiting, waiting_billing_year_division: nil)
      expect(member.waiting_billing_year_division).to eq 12
    end

    it "sets last ACP billing_year_divisions by default " do
      Current.acp.billing_year_divisions = [ 4, 12 ]
      member = create(:member, :waiting, waiting_billing_year_division: 1)
      expect(member.waiting_billing_year_division).to eq 12
    end

    it "only accepts ACP billing_year_divisions" do
      Current.acp.billing_year_divisions = [ 1, 12 ]
      member = build(:member, :waiting, waiting_billing_year_division: 3)

      member.validate
      expect(member.waiting_billing_year_division).to eq 12

      member.waiting_billing_year_division = 1
      member.save!
    end

    it "validates email presence, but only on public creation" do
      member =  Member.new(emails: "")
      expect(member).to have_valid(:emails)

      member.public_create = true
      expect(member).not_to have_valid(:emails)
    end

    it "validates email format" do
      member = Member.new(emails: "doe.com, JANE@doe.com")
      expect(member).not_to have_valid(:emails)

      member = Member.new(emails: "foo@bar.com;JANE@doe.com")
      expect(member).not_to have_valid(:emails)
    end

    it "validates email uniqueness" do
      create(:member, emails: "john@DOE.com, jane@doe.com")
      member = Member.new(emails: "jen@doe.com, JANE@doe.com")

      expect(member).not_to have_valid(:emails)
    end

    it "validates email uniqueness even when emails includes other ones" do
      create(:member, emails: "super-john@DOE.com, mega-jane@doe.com")
      expect(Member.new(emails: "john@DOE.com")).to have_valid(:emails)
      expect(Member.new(emails: "JANE@doe.com")).to have_valid(:emails)
    end

    it "validates annual_fee to be greater or equal to zero" do
      expect(Member.new(annual_fee: nil)).to have_valid(:annual_fee)
      expect(Member.new(annual_fee: 0)).to have_valid(:annual_fee)
      expect(Member.new(annual_fee: 1)).to have_valid(:annual_fee)
      expect(Member.new(annual_fee: -1)).not_to have_valid(:annual_fee)
    end

    it "validates waiting_basket_size presence when a depot is set" do
      member = build(:member,
        waiting_basket_size: nil,
        waiting_depot: create(:depot))

      expect(member).not_to be_valid
      expect(member).not_to have_valid(:waiting_basket_size_id)
    end

    it "validates waiting_basket_price_extra presence" do
      member = build(:member,
        waiting_depot: create(:depot),
        waiting_basket_price_extra: nil)

      expect(member).not_to be_valid
      expect(member).not_to have_valid(:waiting_basket_price_extra)
    end

    it "validates waiting_depot presence" do
      member = build(:member,
        waiting_basket_size: create(:basket_size),
        waiting_depot: nil)

      expect(member).not_to be_valid
      expect(member).not_to have_valid(:waiting_depot_id)
    end

    it "validates desired_acp_shares_number on public create" do
      Current.acp.update!(annual_fee: 50, share_price: nil, shares_number: nil)
      member = build(:member, desired_acp_shares_number: 0)

      member.public_create = nil
      expect(member).to have_valid(:desired_acp_shares_number)
      member.public_create = true
      expect(member).to have_valid(:desired_acp_shares_number)

      Current.acp.update!(annual_fee: nil, share_price: 100, shares_number: 1)

      member.public_create = nil
      expect(member).to have_valid(:desired_acp_shares_number)
      member.public_create = true
      expect(member).not_to have_valid(:desired_acp_shares_number)
      member.desired_acp_shares_number = 1
      expect(member).to have_valid(:desired_acp_shares_number)

      Current.acp.update!(annual_fee: nil, share_price: 100, shares_number: 2)
      expect(member).not_to have_valid(:desired_acp_shares_number)
      member.desired_acp_shares_number = 2
      expect(member).to have_valid(:desired_acp_shares_number)

      basket_size = create(:basket_size, acp_shares_number: 3)
      member.waiting_basket_size_id = basket_size.id
      expect(member).not_to have_valid(:desired_acp_shares_number)
      member.desired_acp_shares_number = 3
      expect(member).to have_valid(:desired_acp_shares_number)
    end

    specify "validates waiting_activity_participations_demanded_annually on public create" do
      Current.acp.update!(features: [ "activity" ])
      member = build(:member, waiting_activity_participations_demanded_annually: nil)

      member.public_create = true

      Current.acp.update!(activity_participations_form_min: 2)
      member.waiting_activity_participations_demanded_annually = 1
      expect(member).not_to have_valid(:waiting_activity_participations_demanded_annually)
      member.waiting_activity_participations_demanded_annually = 2
      expect(member).to have_valid(:waiting_activity_participations_demanded_annually)

      Current.acp.update!(activity_participations_form_max: 4)
      member.waiting_activity_participations_demanded_annually = 5
      expect(member).not_to have_valid(:waiting_activity_participations_demanded_annually)
      member.waiting_activity_participations_demanded_annually = 4
      expect(member).to have_valid(:waiting_activity_participations_demanded_annually)

      member.waiting_activity_participations_demanded_annually = 3
      expect(member).to have_valid(:waiting_activity_participations_demanded_annually)
    end

    specify "required profession mode on public create" do
      Current.acp.update!(member_profession_form_mode: "visible")
      member = build(:member,
        public_create: true,
        profession: nil)

      expect(member).to have_valid(:profession)

      Current.acp.update!(member_profession_form_mode: "required")

      expect(member).not_to have_valid(:profession)
    end

    specify "required come_form mode on public create" do
      Current.acp.update!(member_come_from_form_mode: "visible")
      member = build(:member,
        public_create: true,
        come_from: nil)

      expect(member).to have_valid(:come_from)

      Current.acp.update!(member_come_from_form_mode: "required")

      expect(member).not_to have_valid(:come_from)
    end

    context "with SEPA" do
      before do
        Current.acp.update!(
          country_code: "DE",
          iban: "DE89370400440532013000")
      end

      specify "validates mandate signed on presence" do
        member = Member.new(sepa_mandate_id: "123", sepa_mandate_signed_on: nil)
        expect(member).not_to have_valid(:sepa_mandate_signed_on)
      end

      specify "validates IBAN" do
        member = Member.new(sepa_mandate_id: "123", iban: nil)
        expect(member).not_to have_valid(:iban)

        member.iban = "CH9300762011623852957"
        expect(member).not_to have_valid(:iban)

        member.iban = "DE89370400440532013333"
        expect(member).to have_valid(:iban)
      end
    end
  end

  it "strips whitespaces from emails and downcase" do
    member = Member.new(emails: " foo@Gmail.COM ")

    expect(member.emails_array).to eq [ "foo@gmail.com" ]
  end

  it "initializes with annual_fee from ACP" do
    Current.acp.update!(annual_fee: 42)
    expect(Member.new.annual_fee).to eq 42
  end

  it "initializes with ACP country code" do
    expect(Member.new.country_code).to eq "CH"
    Current.acp.update!(
      country_code: "DE",
      iban: "DE89370400440532013000")
    expect(Member.new.country_code).to eq "DE"
  end

  it "updates waiting basket_size/depot" do
    member = create(:member, :waiting)
    new_basket_size = create(:basket_size)
    new_depot = create(:depot)

    member.update!(
      waiting_basket_size: new_basket_size,
      waiting_depot: new_depot)

    expect(member.state).to eq "waiting"
    expect(member.waiting_started_at).to be_present
    expect(member.waiting_basket_size).to eq new_basket_size
    expect(member.waiting_depot).to eq new_depot
  end

  describe "#current_membership" do
    subject { create(:member, :active).current_membership }

    it { is_expected.to eq Membership.last }
  end

  describe "#billable?" do
    specify "support member" do
      member = create(:member, :support_annual_fee)
      expect(member).to be_billable
    end

    specify "inactive member" do
      member = create(:member, :inactive)
      expect(member).not_to be_billable
    end

    specify "past membership" do
      member = create(:member, :inactive)
      create(:membership, :last_year, member: member)
      expect(member).not_to be_billable
    end

    specify "ongoing membership" do
      member = create(:member, :inactive)
      create(:membership, member: member)
      expect(member).to be_billable
    end

    specify "future membership" do
      member = create(:member, :inactive)
      create(:membership, :next_year, member: member)
      expect(member).to be_billable
    end
  end

  describe "#update_trial_basket_count", freeze: "2024-01-01" do
    specify "ignore absent basket" do
      Current.acp.update!(trial_basket_count: 2)

      create(:delivery, date: "2024-11-01")
      create(:delivery, date: "2024-12-01")
      create(:delivery, date: "2025-01-01")
      create(:delivery, date: "2025-02-01")

      member = create(:member)
      create(:membership, member: member, started_on: "2024-11-01", ended_on: "2024-12-31")
      create(:membership, member: member, started_on: "2025-01-01", ended_on: "2025-12-31")
      create(:absence, member: member, started_on: "2024-11-30", ended_on: "2024-12-10")

      expect(member.baskets.map { |b| [ b.delivery.date.to_s, b.trial? ] }).to eq [
        [ "2024-11-01", true ],
        [ "2024-12-01", false ],
        [ "2025-01-01", true ],
        [ "2025-02-01", false ]
      ]
    end
  end

  describe "#validate!" do
    let(:admin) { create(:admin) }

    it "sets state to waiting if waiting basket/depot" do
      member = create(:member, :pending,
        waiting_basket_size: create(:basket_size))

      expect { member.validate!(admin) }.to change(member, :state).to("waiting")
      expect(member.validated_at).to be_present
      expect(member.validator).to eq admin
    end

    it "sets state to active if shop depot is set" do
      member = create(:member, :pending,
        waiting_basket_size: nil,
        waiting_depot: nil,
        shop_depot: create(:depot))

      expect { member.validate!(admin) }.to change(member, :state).to("active")
      expect(member.validated_at).to be_present
      expect(member.validator).to eq admin
    end

    it "sets state to support if annual_fee is present" do
      member = create(:member, :pending,
        waiting_basket_size: nil,
        waiting_depot: nil,
        annual_fee: 30)

      expect { member.validate!(admin) }.to change(member, :state).to("support")
      expect(member.validated_at).to be_present
      expect(member.validator).to eq admin
    end

    it "sets state to inactive if annual_fee is not present" do
      member = create(:member, :pending,
        waiting_basket_size: nil,
        waiting_depot: nil,
        annual_fee: nil)

      expect { member.validate!(admin) }.to change(member, :state).to("inactive")
      expect(member.validated_at).to be_present
      expect(member.validator).to eq admin
    end

    it "sets state to support if desired_acp_shares_number is present" do
      Current.acp.update!(annual_fee: nil, share_price: 100, shares_number: 1)
      member = create(:member, :pending,
        desired_acp_shares_number: 10,
        waiting_basket_size: nil,
        waiting_depot: nil,
        annual_fee: nil)

      expect { member.validate!(admin) }.to change(member, :state).to("support")
      expect(member.validated_at).to be_present
      expect(member.validator).to eq admin
    end

    it "raise if not pending" do
      member = create(:member, :support_annual_fee)
      expect { member.validate!(admin) }.to raise_error(InvalidTransitionError)
    end
  end

  describe "#wait!" do
    it "sets state to waiting and reset waiting_started_at" do
      Current.acp.update!(annual_fee: 30)
      member = create(:member, :support_annual_fee,
        waiting_started_at: 1.month.ago,
        annual_fee: 42)

      expect { member.wait! }.to change(member, :state).to("waiting")
      expect(member.waiting_started_at).to be > 1.minute.ago
      expect(member.annual_fee).to eq 42
    end

    it "sets state to waiting and set default annual_fee" do
      Current.acp.update!(annual_fee: 30)
      member = create(:member, :inactive)

      expect { member.wait! }.to change(member, :state).to("waiting")
      expect(member.waiting_started_at).to be > 1.minute.ago
      expect(member.annual_fee).to eq 30
    end

    it "raise if not support or inactive" do
      member = create(:member, :pending)
      expect { member.wait! }.to raise_error(InvalidTransitionError)
    end
  end

  describe "#review_active_state!" do
    it "activates new active member", freeze: "01-06-2018" do
      member = create(:member, :inactive)
      membership = create(:membership,
        member: member,
        ended_on: 1.day.ago)
      membership.update_column(:ended_on, 1.day.from_now)
      member.reload

      expect { member.review_active_state! }
        .to change(member, :state).from("inactive").to("active")
    end

    it "activates new inactive member with shop_depot" do
      depot = create(:depot)
      member = create(:member, :inactive)
      member.update_column(:shop_depot_id, depot.id)

      expect { member.review_active_state! }
        .to change(member, :state).from("inactive").to("active")
    end

    it "deactivates old active member", freeze: "01-06-2018" do
      member = create(:member, :active)
      member.membership.update_column(:ended_on, 1.day.ago)
      member.reload

      expect { member.review_active_state! }
        .to change(member, :state).from("active").to("inactive")
    end

    it "sets state to support when membership.renewal_annual_fee is present" do
      membership = create(:membership)
      member = membership.member
      membership.cancel!(renewal_annual_fee: "1")

      travel 1.year do
        member.reload
        expect { member.review_active_state! }
          .to change(member, :state).to("support")
        expect(member.annual_fee).to eq 30
      end
    end

    it "sets state to support when user still has acp_shares", freeze: "2021-06-15" do
      Current.acp.update!(share_price: 100, shares_number: 1, annual_fee: nil)
      member = create(:member, :active)
      member.membership.update_column(:ended_on, 1.day.ago)
      create(:invoice, member: member, acp_shares_number: 1, entity_type: "ACPShare")

      expect(member.acp_shares_number).to eq 1
      expect { member.review_active_state! }
        .to change { member.reload.state }.to("support")
      expect(member.annual_fee).to be_nil
    end

    it "sets state to inactive and desired_acp_shares_number to 0 when membership ended", freeze: "2021-06-15" do
      Current.acp.update!(share_price: 100, shares_number: 1, annual_fee: nil)
      member = create(:member, :trial)
      member.update!(desired_acp_shares_number: 1)
      member.membership.update_column(:ended_on, 1.day.ago)

      expect { member.review_active_state! }
        .to change { member.reload.state }.to("inactive")
        .and change { member.reload.desired_acp_shares_number }.from(1).to(0)
      expect(member.annual_fee).to be_nil
      expect(member.acp_shares_number).to eq 0
    end
  end

  specify "#emails= / #emails" do
    member = Member.new(emails: "john@doe.com, foo@bar.com")
    expect(member.emails).to eq "john@doe.com, foo@bar.com"
  end

  describe "#phones= / #phones" do
    specify "two phones" do
      member = create(:member, phones: "123456789, 987654321, ")
      expect(member.phones).to eq "+41123456789, +41987654321"
    end

    specify "two phones with spaces and dots" do
      member = create(:member, phones: "+41.12.345/67 89, 987/6543 21, ")
      expect(member.phones).to eq "+41123456789, +41987654321"
    end

    context "other country phone" do
      before do
        Current.acp.update!(
          country_code: "DE",
          iban: "DE89370400440532013000")
      end

      specify "use member country code" do
        member = create(:member, phones: "987 6543 21, ", country_code: "FR")
        expect(member.phones).to eq "+33987654321"
      end

      specify "use ACP country code" do
        member = create(:member, :inactive, phones: "987 6543 21, ", country_code: nil)
        expect(member.phones).to eq "+49987654321"
      end
    end
  end

  describe "#absent?" do
    it "returns true for a given date during the absence window" do
      absence = create(:absence,
        started_on: 2.weeks.from_now,
        ended_on: 4.weeks.from_now)

      expect(absence.member.absent?(3.weeks.from_now)).to eq true
    end
  end

  describe "#activate!" do
    before { MailTemplate.find_by(title: :member_activated).update!(active: true) }

    it "activates new active member and sent member-activated email", sidekiq: :inline do
      travel_to(Date.new(Current.fy_year, 1, 15)) do
        member = create(:member, :inactive, activated_at: nil)
        membership = create(:membership,
          member: member,
          ended_on: 1.day.ago)
        membership.update_column(:ended_on, 1.day.from_now)
        member.reload

        expect { member.activate! }
          .to change(member, :state).from("inactive").to("active")
          .and change(member, :activated_at).from(nil)
          .and change { MemberMailer.deliveries.size }.by(1)

        mail = MemberMailer.deliveries.last
        expect(mail.subject).to eq "Bienvenue!"
      end
    end

    it "activates previously active member" do
      travel_to(Date.new(Current.fy_year, 1, 15)) do
        member = create(:member, :inactive, activated_at: 1.year.ago)
        membership = create(:membership,
          member: member,
          ended_on: 1.day.ago)
        membership.update_column(:ended_on, 1.day.from_now)
        member.reload

        expect { member.activate! }
          .not_to change(member, :activated_at)

        expect(MemberMailer.deliveries).to be_empty
      end
    end
  end

  describe "#deactivate!" do
    it "sets state to inactive and clears waiting_started_at, annual_fee, and shop_depot" do
      member = create(:member, :waiting,
        annual_fee: 42,
        shop_depot: create(:depot))

      expect { member.deactivate! }.to change(member, :state).to("inactive")
      expect(member.waiting_started_at).to be_nil
      expect(member.annual_fee).to be_nil
      expect(member.shop_depot).to be_nil
    end

    it "sets state to inactive and clears annual_fee" do
      member = create(:member, :support_annual_fee, annual_fee: 42)

      expect { member.deactivate! }.to change(member, :state).to("inactive")
      expect(member.annual_fee).to be_nil
    end

    it "sets state to inactive when membership ended" do
      member = create(:member, :active)
      member.membership.update_column(:ended_on, 1.day.ago)
      member.reload

      expect { member.deactivate! }.to change(member, :state).to("inactive")
      expect(member.annual_fee).to be_nil
    end

    it "raise if current membership" do
      member = create(:member, :active)

      expect { member.deactivate! }.to raise_error(InvalidTransitionError)
    end
  end

  describe "notify_new_inscription_to_admins" do
    it "notifies admin with new_inscription notifications on when publicly created", sidekiq: :inline do
      admin1 = create(:admin, notifications: [ "new_inscription" ])
      admin2 = create(:admin, notifications: [])

      member = create(:member, :waiting,
        name: "John Doe",
        public_create: true)

      expect(AdminMailer.deliveries.size).to eq 1
      mail = AdminMailer.deliveries.last
      expect(mail.subject).to eq "Nouvelle inscription"
      expect(mail.to).to eq [ admin1.email ]
      expect(mail.body.encoded).to include admin1.name
      expect(mail.body.encoded).to include "John Doe"
    end

    it "does not notify admin when not publicly created" do
      create(:admin, notifications: [ "new_inscription" ])
      create(:member, :waiting)

      expect(AdminMailer.deliveries).to be_empty
    end
  end

  describe "#update_membership_if_salary_basket_changed" do
    it "updates current year membership price" do
      membership = create(:membership)
      member = membership.member

      expect { member.reload.update!(salary_basket: true) }
        .to change { membership.reload.price }.to(0)
        .and change { membership.reload.activity_participations_demanded }.from(2).to(0)
    end

    it "updates future membership price" do
      membership = create(:membership, :next_year)
      member = membership.member

      expect { member.reload.update!(salary_basket: true) }
        .to change { membership.reload.price }.to(0)
        .and change { membership.reload.activity_participations_demanded }.from(2).to(0)
    end
  end

  describe "#handle_annual_fee_change" do
    it "changes inactive state to support when annual_fee is set" do
      member = create(:member, :inactive)
      expect { member.update!(annual_fee: 30) }
        .to change(member, :state).to("support")
    end

    it "changes support state to inactive when annual_fee is cleared" do
      member = create(:member, :support_annual_fee)
      expect { member.update!(annual_fee: nil) }
        .to change(member, :state).to("inactive")
    end
  end

  describe "#missing_acp_shares_number" do
    specify "when desired_acp_shares_number only" do
      member = Member.new(
        desired_acp_shares_number: 10,
        existing_acp_shares_number: 0)
      expect(member.missing_acp_shares_number).to eq 10
    end

    specify "when matching existing_acp_shares_number" do
      member = Member.new(
        desired_acp_shares_number: 5,
        existing_acp_shares_number: 5)
      expect(member.missing_acp_shares_number).to eq 0
    end

    specify "when more existing_acp_shares_number" do
      member = Member.new(
        desired_acp_shares_number: 5,
        existing_acp_shares_number: 6)
      expect(member.missing_acp_shares_number).to eq 0
    end

    specify "when less existing_acp_shares_number" do
      member = Member.new(
        desired_acp_shares_number: 6,
        existing_acp_shares_number: 4)
      expect(member.missing_acp_shares_number).to eq 2
    end

    specify "when requiring more membership shares" do
      basket_size = create(:basket_size, acp_shares_number: 2)
      member = create(:member,
        desired_acp_shares_number: 1,
        existing_acp_shares_number: 0)
      create(:membership, member: member, basket_size: basket_size)
      expect(member.missing_acp_shares_number).to eq 2
    end

    specify "when explicitly requiring more shares" do
      basket_size = create(:basket_size, acp_shares_number: 2)
      member = create(:member,
        desired_acp_shares_number: 1,
        existing_acp_shares_number: 0,
        required_acp_shares_number: 3)
      create(:membership, member: member, basket_size: basket_size)
      expect(member.missing_acp_shares_number).to eq 3
    end

    specify "when explicitly requiring less shares but still desired one" do
      basket_size = create(:basket_size, acp_shares_number: 2)
      member = create(:member,
        desired_acp_shares_number: 0,
        existing_acp_shares_number: 0,
        required_acp_shares_number: 0)
      create(:membership, member: member, basket_size: basket_size)
      expect(member.missing_acp_shares_number).to eq 0
    end

    specify "when explicitly requiring less shares but still desired one" do
      basket_size = create(:basket_size, acp_shares_number: 2)
      member = create(:member,
        desired_acp_shares_number: 1,
        existing_acp_shares_number: 0,
        required_acp_shares_number: 0)
      create(:membership, member: member, basket_size: basket_size)
      expect(member.missing_acp_shares_number).to eq 1
    end
  end

  describe "#can_destroy?" do
    specify "can destroy pending user" do
      member = Member.new(state: "pending")
      expect(member.can_destroy?).to eq true
    end

    specify "can destroy inactive member with no memberships and no invoices" do
      member = create(:member, :inactive)
      expect(member.can_destroy?).to eq true
    end

    specify "cannot destory inactive member with membership" do
      member = create(:member, :inactive)
      create(:membership, :last_year, member: member)
      expect(member.reload).to be_inactive
      expect(member.can_destroy?).to eq false
    end

    specify "cannot destory inactive member with invoices" do
      member = create(:member, :inactive)
      create(:invoice, :annual_fee, member: member, annual_fee: 10)
      expect(member.reload).to be_inactive
      expect(member.can_destroy?).to eq false
    end
  end

  describe "#set_default_waiting_delivery_cycle" do
    specify "when basket_size has a delivery_cycle" do
      dc_1 = create(:delivery_cycle)
      dc_2 = create(:delivery_cycle)
      basket_size = create(:basket_size, delivery_cycle: dc_2)
      depot = create(:depot, delivery_cycles: [ dc_1 ])

      member = create(:member, :waiting,
        waiting_basket_size: basket_size,
        waiting_depot: depot,
        waiting_delivery_cycle_id: nil)

      expect(member.waiting_delivery_cycle).to eq dc_2
    end

    specify "when basket_size has no delivery_cycle" do
      create_deliveries(2)
      dc_1 = create(:delivery_cycle, results: :odd)
      dc_2 = create(:delivery_cycle)
      dc_3 = create(:delivery_cycle) # max deliveries count
      depot = create(:depot, delivery_cycles: [ dc_1, dc_3 ])

      member = create(:member, :waiting,
        waiting_depot: depot,
        waiting_delivery_cycle_id: nil)

      expect(member.waiting_delivery_cycle).to eq dc_3
    end
  end
end
