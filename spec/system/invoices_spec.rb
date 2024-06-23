# frozen_string_literal: true

require "rails_helper"

describe "Invoices" do
  it "creates an invoice for a rejected activity participation", sidekiq: :inline do
    member = create(:member, name: "Jean Paul")
    create(:membership, id: 42, member: member)
    create(:activity_participation, :rejected,
      id: 3,
      member: member,
      participants_count: 2)

    login create(:admin, name: "Sheriff")

    visit "/activity_participations/3"
    click_link "Facturer"

    fill_in "Commentaire", with: "A oublier de venir."
    click_button "Créer Facture"

    expect(page)
      .to have_content("Détails")
      .and have_content("Membre Jean Paul")
      .and have_content("Objet Participation #3")
      .and have_content("Nombre / Participants 2")
      .and have_content("ouverte")
      .and have_content("Non")
      .and have_content("Montant CHF 120.00")
      .and have_content("Commentaires")
      .and have_content("Sheriff")
      .and have_content("A oublier de venir.")
  end
end
