class ResearchForDevelopmentOutput < Document
  validates :first_published_at, presence: true, date: true
  validates :theme, presence: true
  validates :research_document_type, presence: true

  FORMAT_SPECIFIC_FIELDS = %i[
    research_document_type
    country
    first_published_at
    authors
    theme
    review_status
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
    self.author_tags = params[:author_tags]
  end

  def taxons
    [INTERNATIONAL_AID_AND_DEVELOPMENT_TAXON_ID]
  end

  ##
  # Research for Development outputs are always bulk published, because our 'publication'
  # is just a proxy for a research output PDF. Its date is not important to a
  # user. Setting this +true+ means that specialist-frontend will never render
  # the publishing-api +published+ date.
  def bulk_published
    true
  end

  def self.title
    "Research for Development Output"
  end

  def author_tags
    (authors || []).join("::")
  end

  def author_tags=(tags)
    self.authors = (tags || "").split("::")
  end

  def primary_publishing_organisation
    "f9fcf3fe-2751-4dca-97ca-becaeceb4b26"
  end
end
