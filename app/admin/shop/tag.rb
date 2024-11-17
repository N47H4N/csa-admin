# frozen_string_literal: true

ActiveAdmin.register Shop::Tag do
  menu false
  actions :all, except: [ :show ]

  breadcrumb do
    links = [
      t("active_admin.menu.shop"),
      link_to(Shop::Product.model_name.human(count: 2), shop_products_path)
    ]
    unless params["action"] == "index"
      links << link_to(Shop::Tag.model_name.human(count: 2), shop_tags_path)
    end
    links
  end

  includes :products

  index download_links: false do
    column :name, ->(tag) { link_to tag.display_name, [ :edit, tag ] }, sortable: true
    column :products, ->(tag) {
      link_to(
        tag.products.size,
        shop_products_path(
          q: { tags_id_eq: tag.id }))
    }, class: "text-right"
    actions
  end

  form do |f|
    f.inputs t(".details") do
      translated_input(f, :names)
      f.input :emoji, input_html: { data: { controller: "emoji-button", emoji_button_target: "button", action: "click->emoji-button#toggle" }, class: "emoji-button", size: 1 }
    end
    f.actions
  end

  permit_params(
    :emoji,
    *I18n.available_locales.map { |l| "name_#{l}" })

  controller do
    def scoped_collection
      super.kept
    end
  end

  order_by(:name) do |clause|
    config
      .resource_class
      .order_by_name(clause.order)
      .order_values
      .join(" ")
  end

  config.filters = false
  config.sort_order = "name_asc"
end
