require "spec_helper"
require "publishing_api_finder_publisher"

RSpec.describe PublishingApiFinderPublisher do
  describe "#call" do
    def make_file(base_path, overrides = {})
      underscore_name = base_path.sub("/", "")
      name = underscore_name.humanize
      json = {
        "base_path" => base_path,
        "name" => name,
        "content_id" => SecureRandom.uuid,
        "format" => "#{underscore_name}_format",
        "logo_path" => "http://example.com/logo.png",
        "facets" => [
          {
            "key" => "report_type",
            "name" => "Report type",
            "type" => "text",
            "display_as_result_metadata" => true,
            "filterable" => true,
          },
        ],
        "document_noun" => "reports",
      }.merge(overrides)

      json
    end

    def make_finder(base_path, overrides = {})
      {
        file: make_file(base_path, overrides),
        timestamp: "2015-01-05T10:45:10.000+00:00".to_time,
      }
    end

    let(:publishing_api) { double("publishing-api") }

    let(:test_logger) { Logger.new(nil) }

    before do
      allow(Services).to receive(:publishing_api)
        .and_return(publishing_api)

      stub_any_publishing_api_put_content
      stub_any_publishing_api_patch_links
    end

    describe "publishing finders" do
      let(:finders) do
        [
          make_finder("/first-finder", "signup_content_id" => SecureRandom.uuid),
          make_finder("/second-finder"),
        ]
      end

      it "uses GdsApi::PublishingApi" do
        stub_publishing_api_publish(finders[0][:file]["content_id"], {})
        stub_publishing_api_publish(finders[0][:file]["signup_content_id"], {})
        stub_publishing_api_publish(finders[1][:file]["content_id"], {})

        expect(publishing_api).to receive(:put_content)
          .with(finders[0][:file]["content_id"], be_valid_against_schema("finder"))
        expect(publishing_api).to receive(:patch_links)
          .with(finders[0][:file]["content_id"], anything)
        expect(publishing_api).to receive(:publish)
          .with(finders[0][:file]["content_id"])

        # This should be validated against an email-signup schema if one gets created
        expect(publishing_api).to receive(:put_content)
          .with(finders[0][:file]["signup_content_id"], anything)
        expect(publishing_api).to receive(:patch_links)
          .with(finders[0][:file]["signup_content_id"], anything)
        expect(publishing_api).to receive(:publish)
          .with(finders[0][:file]["signup_content_id"])

        expect(publishing_api).to receive(:put_content)
          .with(finders[1][:file]["content_id"], be_valid_against_schema("finder"))
        expect(publishing_api).to receive(:patch_links)
          .with(finders[1][:file]["content_id"], anything)
        expect(publishing_api).to receive(:publish)
          .with(finders[1][:file]["content_id"])

        PublishingApiFinderPublisher.new(finders, logger: test_logger).call
      end
    end

    context "when the finder has a `phase`" do
      let(:finders) do
        [
          make_finder("/finder-with-phase", "phase" => "beta"),
        ]
      end

      let(:content_id) { finders[0]["content_id"] }

      before do
        stub_any_publishing_api_put_content
        stub_any_publishing_api_patch_links
        stub_publishing_api_publish(content_id, {})
      end

      it "publishes finder" do
        expect(publishing_api).to receive(:put_content)
          .with(finders[0][:file]["content_id"], be_valid_against_schema("finder"))
        expect(publishing_api).to receive(:patch_links)
          .with(finders[0][:file]["content_id"], anything)
        expect(publishing_api).to receive(:publish)
          .with(finders[0][:file]["content_id"])

        PublishingApiFinderPublisher.new(finders, logger: test_logger).call
      end
    end

    context "when the finder isn't `pre_production`" do
      let(:finders) do
        [
          make_finder("/not-pre-production-finder", "pre_production" => false),
        ]
      end

      let(:content_id) { finders[0][:file]["content_id"] }

      before do
        stub_any_publishing_api_put_content
        stub_any_publishing_api_patch_links
        stub_publishing_api_publish(content_id, {})
      end

      it "publishes finder" do
        expect(publishing_api).to receive(:put_content)
          .with(content_id, be_valid_against_schema("finder"))
        expect(publishing_api).to receive(:patch_links)
          .with(content_id, anything)
        expect(publishing_api).to receive(:publish)
          .with(content_id)

        PublishingApiFinderPublisher.new(finders, logger: test_logger).call
      end
    end

    context "when the finder is `pre_production`" do
      let(:finders) do
        [
          make_finder("/pre-production-finder", "pre_production" => true),
        ]
      end

      let(:content_id) { finders[0][:file]["content_id"] }

      context "and the app is configured to publish pre-production finders" do
        before do
          SpecialistPublisher.publish_pre_production_finders = true

          stub_publishing_api_publish(content_id, {})
        end

        after do
          SpecialistPublisher.publish_pre_production_finders = false
        end

        it "publishes finder" do
          expect(publishing_api).to receive(:put_content)
            .with(content_id, be_valid_against_schema("finder"))
          expect(publishing_api).to receive(:patch_links)
            .with(content_id, anything)
          expect(publishing_api).to receive(:publish)
            .with(content_id)

          PublishingApiFinderPublisher.new(finders, logger: test_logger).call
        end
      end

      context "and is not configured to publish pre-production finders" do
        it "doesn't publish the finder" do
          expect(publishing_api).not_to receive(:put_content)
            .with(content_id, be_valid_against_schema("finder"))
          expect(publishing_api).not_to receive(:patch_links)
            .with(content_id, anything)
          expect(publishing_api).not_to receive(:publish)
            .with(content_id)

          PublishingApiFinderPublisher.new(finders, logger: test_logger).call
        end
      end
    end
  end
end
