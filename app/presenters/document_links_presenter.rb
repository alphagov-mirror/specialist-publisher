class DocumentLinksPresenter
  def initialize(document)
    @document = document
  end

  def to_json
    {
      content_id: document.content_id,
      links: {
        organisations: document.schema_organisations,
        primary_publishing_organisation: [document.primary_publishing_organisation],
        taxons: document.taxons
      },
    }
  end

private

  attr_reader :document
end
