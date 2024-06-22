# frozen_string_literal: true

class AddIsrAndManualBalancesToInvoices < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :isr_balance, :decimal, scale: 2, precision: 8, default: 0, null: false
    add_column :invoices, :manual_balance, :decimal, scale: 2, precision: 8, default: 0, null: false
    change_column_default :invoices, :balance, 0
    Invoice.where(balance: nil).update_all(balance: 0)
    change_column_null :invoices, :balance, false
  end
end
