class Document < ActiveRecord::Base
  belongs_to :tender
  
  attr_accessible :tender_id,
      :document_url,
      :title,
      :author,
      :date
      
  validates :tender_id, :document_url, :presence => true
end
