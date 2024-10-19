# frozen_string_literal: true

class Liquid::AdminDrop < Liquid::Drop
  def initialize(admin)
    @admin = admin
  end

  def name
    @admin.name
  end

  def email
    @admin.email
  end

  def type
    Admin.model_name.human
  end

  def admin_url
    Rails
      .application
      .routes
      .url_helpers
      .admin_url(@admin.id, {}, host: Current.org.admin_url)
  end
end
