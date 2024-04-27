class MembershipsBasketComplement < ApplicationRecord
  include HasDescription

  belongs_to :membership, touch: true
  belongs_to :basket_complement, touch: true
  belongs_to :delivery_cycle, optional: true

  validates :basket_complement_id, uniqueness: { scope: :membership_id }
  validates :price, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 1 }, presence: true

  scope :current_and_future_year, -> {
    joins(:membership).merge(Membership.current_and_future_year)
  }

  before_validation do
    self.price ||= basket_complement&.price
  end

  def description(public_name: false)
    describe(basket_complement, quantity, public_name: public_name)
  end
end
