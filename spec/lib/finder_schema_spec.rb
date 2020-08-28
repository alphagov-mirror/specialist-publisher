require "spec_helper"
require "finder_schema"

RSpec.describe FinderSchema do
  describe ".schema_names" do
    it "returns schema names" do
      expect(FinderSchema.schema_names).to include("aaib_reports")
    end
  end

  let(:schema) { FinderSchema.new("research_for_development_outputs") }

  describe "#humanized_facet_name" do
    it "returns the name defined in the schema for the supplied facet key" do
      expect(schema.humanized_facet_name("research_document_type")).to eq("Document Type")
    end

    it "returns the humanized version of the supplied facet key is not defined in the schema" do
      expect(schema.humanized_facet_name("review_status")).to eq("Review status")
    end
  end

  describe "#humanized_facet_value" do
    context "a text facet" do
      context "with allowed_values " do
        context "looking up a single value" do
          it "returns an array with only the looked-up value" do
            expect(schema.humanized_facet_value("country", "AL")).to eql(%w[Albania])
          end
        end

        context "looking up multiple values" do
          it "returns an array with the looked-up values" do
            expect(schema.humanized_facet_value("country", %w[AL AF])).to eql(%w[Albania Afghanistan])
          end
        end
      end

      context "with an empty set of allowed_values" do
        it "returns the value itself" do
          authors_value = ["Mr. Potato Head", "Mrs. Potato Head"]
          expect(
            schema.humanized_facet_value("authors", authors_value),
          ).to eql(authors_value)
        end
      end
    end

    context "a date facet" do
      it "just returns the value unmodified" do
        expect(schema.humanized_facet_value("first_published_at", "2012-01-01")).to eql("2012-01-01")
      end
    end
  end
end
