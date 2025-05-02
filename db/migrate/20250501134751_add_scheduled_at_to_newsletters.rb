# frozen_string_literal: true

class AddScheduledAtToNewsletters < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletters, :scheduled_at, :datetime
  end
end
