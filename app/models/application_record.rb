class ApplicationRecord < ActiveRecord::Base
  include RansackableAttributesConcern
  primary_abstract_class
end
