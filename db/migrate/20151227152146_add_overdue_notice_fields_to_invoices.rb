# frozen_string_literal: true

class AddOverdueNoticeFieldsToInvoices < ActiveRecord::Migration[4.2]
  def change
    remove_column :invoices, :overdue_notices
    add_column :invoices, :overdue_notices_count, :integer, null: false, default: 0
    add_column :invoices, :overdue_notice_sent_at, :datetime
  end
end
