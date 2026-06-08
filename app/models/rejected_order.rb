class RejectedOrder < ApplicationRecord
  belongs_to :dealer

  enum :status, { rejected: 0 }, suffix: true
end
