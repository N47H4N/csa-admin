# frozen_string_literal: true

class CreateMembers < ActiveRecord::Migration[4.2]
  def change
    create_table :members do |t|
      t.string :emails, array: true
      t.string :phones, array: true
      t.string :name, null: false
      t.string :address
      t.string :zip
      t.string :city
      t.string :token, null: false

      t.timestamps
    end
  end
end
