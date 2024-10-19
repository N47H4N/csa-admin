# frozen_string_literal: true

class Liquid::AdminMemberDrop < Liquid::Drop
  def initialize(member)
    @member = member
  end

  def name
    @member.name
  end

  def type
    Member.model_name.human
  end

  def admin_url
    Rails
      .application
      .routes
      .url_helpers
      .member_url(@member.id, {}, host: Current.org.admin_url)
  end
end
