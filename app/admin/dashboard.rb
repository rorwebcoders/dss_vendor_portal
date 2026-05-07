# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "Portal Overview" do
          ul do
            li "Dealers: #{Dealer.count}"
            li "Users: #{User.count}"
            li "Purchase Orders: #{PurchaseOrder.count}"
            li "Line Items: #{LineItem.count}"
          end
        end
      end
    end
  end
end
