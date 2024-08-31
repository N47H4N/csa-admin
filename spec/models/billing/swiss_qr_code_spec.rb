# frozen_string_literal: true

require "rails_helper"

describe Billing::SwissQRCode do
  before {
    Current.org.update!(
      country_code: "CH",
      iban: "CH4431999123000889012",
      creditor_name: "Robert Schneider AG",
      creditor_address: "Rue du Lac 1268",
      creditor_city: "Biel",
      creditor_zip: "2501",
      invoice_info: "Payable dans les 30 jours, avec nos remerciements.",
      invoice_footer: "<b>Association Rage de Vert</b>, Closel-Bourbon 3, 2075 Thielle /// info@ragedevert.ch, 076 481 13 84")
  }
  let(:member) {
    create(:member,
      id: 1234,
      name: "Pia-Maria Rutschmann-Schnyder",
      address: "Grosse Marktgasse 28",
      zip: "9400",
      city: "Rorschach",
      country_code: "CH")
  }

  specify "#payload" do
    invoice = create(:invoice, :annual_fee, id: 706, member: member)
    invoice.payments.create!(amount: 10, date: Date.today)
    payload = Billing::SwissQRCode.new(invoice.reload).payload
    expect(payload).to eq(
      "SPC\r\n" +
      "0200\r\n" +
      "1\r\n" +
      "CH4431999123000889012\r\n" +
      "S\r\n" +
      "Robert Schneider AG\r\n" +
      "Rue du Lac 1268\r\n" +
      "\r\n" +
      "2501\r\n" +
      "Biel\r\n" +
      "CH\r\n" +
      "\r\n" +
      "\r\n" +
      "\r\n" +
      "\r\n" +
      "\r\n" +
      "\r\n" +
      "\r\n" +
      "20.00\r\n" +
      "CHF\r\n" +
      "S\r\n" +
      "Pia-Maria Rutschmann-Schnyder\r\n" +
      "Grosse Marktgasse 28\r\n" +
      "\r\n" +
      "9400\r\n" +
      "Rorschach\r\n" +
      "CH\r\n" +
      "QRR\r\n" +
      "000000000000012340000007067\r\n" +
      "Facture 706\r\n" +
      "EPD\r\n" +
      "\r\n")
  end

  specify "#generate" do
    expected = Vips::Image.new_from_file(file_fixture("qrcode-706.png").to_s)
    invoice = create(:invoice, :annual_fee, id: 706, member: member)
    qr_image = Billing::SwissQRCode.new(invoice).generate(rails_env: "not_test")
    result = Vips::Image.new_from_file(qr_image.path)
    diff = (result - expected).abs.max
    expect(diff).to eq 0
  end
end
