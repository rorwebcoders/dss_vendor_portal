class DealerLog < ApplicationRecord
  enum :status, { rejected: 0 }, suffix: true
end
