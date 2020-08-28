FactoryBot.define do
  factory :user do
    sequence(:uid) { |n| "uid-#{n}" }
    sequence(:name) { |n| "Joe Bloggs #{n}" }
    sequence(:email) { |n| "joe#{n}@bloggs.example.com" }
    if defined?(GDS::SSO::Config)
      # Grant permission to signin to the app using the gem
      permissions { %w[signin] }
    end
  end

  # Editor factories:
  factory :editor, parent: :user do
    permissions { %w[signin editor] }
  end

  factory :gds_editor, parent: :user do
    organisation_slug { "government-digital-service" }
    permissions { %w[signin gds_editor] }
  end

  factory :statutory_instrument_editor, parent: :user do
    permissions { %w[signin statutory_instrument_editor] }
  end

  factory :cma_editor, parent: :editor do
    organisation_slug { "competition-and-markets-authority" }
    organisation_content_id { "957eb4ec-089b-4f71-ba2a-dc69ac8919ea" }
  end

  factory :moj_editor, parent: :editor do
    organisation_slug { "ministry-of-justice" }
    organisation_content_id { "dcc907d6-433c-42df-9ffb-d9c68be5dc4d" }
  end

  factory :incorrect_id_editor, parent: :editor do
    organisation_slug { "competition-and-markets-authority" }
    organisation_content_id { "ycd9e3dh-222g-3h5f-gsaa-v2f28berrc3a" }
  end

  factory :aaib_editor, parent: :editor do
    organisation_slug { "air-accidents-investigation-branch" }
    organisation_content_id { "38eb5d8f-2d89-480c-8655-e2e7ac23f8f4" }
  end

  factory :dfid_editor, parent: :editor do
    organisation_slug { "department-for-international-development" }
    organisation_content_id { "db994552-7644-404d-a770-a2fe659c661f" }
  end

  factory :research_for_development_output_editor, parent: :editor do
    organisation_slug { "foreign-commonwealth-development-office" }
    organisation_content_id { "f9fcf3fe-2751-4dca-97ca-becaeceb4b26" }
  end

  # Writer factories:
  factory :writer, aliases: [:cma_writer], parent: :editor do
    organisation_slug { "competition-and-markets-authority" }
    organisation_content_id { "957eb4ec-089b-4f71-ba2a-dc69ac8919ea" }
    permissions { %w[signin] }
  end

  factory :moj_writer, parent: :writer do
    organisation_slug { "ministry-of-justice" }
    organisation_content_id { "dcc907d6-433c-42df-9ffb-d9c68be5dc4d" }
  end

  sequence :content_id do |_|
    SecureRandom.uuid
  end

  factory :document, class: Hash do
    content_id
    base_path { "/example-document" }
    title { "Example document" }
    description { "This is the summary of example document" }
    schema_name { "specialist_document" }
    document_type { nil }
    publishing_app { "specialist-publisher" }
    rendering_app { "government-frontend" }
    locale { "en" }
    phase { "live" }
    redirects { [] }
    update_type { "major" }
    public_updated_at { "2015-11-16T11:53:30+00:00" }
    first_published_at { nil }
    last_edited_at { "2015-11-15T11:53:30" }
    publication_state { "draft" }
    state_history do
      { "1": "draft" }
    end
    links { {} }

    routes do
      [
        {
          "path" => base_path,
          "type" => "exact",
        },
      ]
    end

    details { default_details }

    transient do
      default_details do
        {
          "body" => [
            {
              "content_type" => "text/govspeak",
              "content" => "default text",
            },
          ],
          "metadata" => default_metadata,
          "max_cache_time" => 10,
          "temporary_update_type" => false,
        }
      end
      default_metadata { {} }
    end

    initialize_with do
      merged_details = default_details.deep_stringify_keys.deep_merge(details.deep_stringify_keys)
      result = attributes.merge(details: merged_details)
      if document_type
        result = result.merge(
          links: {
            finder: [FinderSchema.new(document_type.pluralize).content_id],
          },
        )
      end

      result
    end

    # This is the default document state.
    trait :draft do
    end

    trait :published do
      publication_state { "published" }
      first_published_at { "2015-11-15T00:00:00+00:00" }
      state_history do
        { "1": "published" }
      end
    end

    trait :redrafted do
      state_history do
        { "2": "draft", "1": "published" }
      end

      publication_state { "draft" }
      first_published_at { "2015-11-15T00:00:00+00:00" }

      update_type { "major" }
    end

    trait :unpublished do
      publication_state { "unpublished" }
      first_published_at { "2015-11-15T00:00:00+00:00" }
      state_history do
        { "1": "unpublished" }
      end
    end

    to_create(&:deep_stringify_keys!)
  end

  factory :aaib_report, parent: :document do
    base_path { "/aaib-reports/example-document" }
    document_type { "aaib_report" }

    transient do
      default_metadata do
        {
          "date_of_occurrence" => "2015-10-10",
          "aircraft_category" => %w[commercial-fixed-wing],
          "report_type" => "annual-safety-report",
          "location" => "Near Popham Airfield, Hampshire",
          "aircraft_type" => "Alpi (Cavaciuti) Pioneer 400",
          "registration" => "G-CGVO",
        }
      end
    end
  end

  factory :marine_notice, parent: :document do
    base_path { "/marine-notices/example-document" }

    document_type { "marine_notice" }

    transient do
      default_metadata do
        {
          "marine_notice_type" => "marine-guidance-note",
          "marine_notice_vessel_type" => %w[pleasure-vessels high-speed-craft],
          "marine_notice_topic" => %w[crew-and-training navigation],
          "issued_date" => "2015-10-10",
        }
      end
    end
  end

  factory :service_standard_report, parent: :document do
    base_path { "/service-standard-reports/example-document" }
    document_type { "service_standard_report" }

    transient do
      default_metadata do
        {
          "assessment_date" => "2016-10-10",
          "result" => "met",
          "stage" => "live",
        }
      end
    end
  end

  factory :asylum_support_decision, parent: :document do
    base_path { "/asylum-support-tribunal-decisions/example-document" }
    document_type { "asylum_support_decision" }

    transient do
      default_metadata do
        {
          "hidden_indexable_content" => "some hidden content",
          "tribunal_decision_categories" => %w[section-95-support-for-asylum-seekers],
          "tribunal_decision_decision_date" => "2015-10-10",
          "tribunal_decision_judges" => %w[bayati-c],
          "tribunal_decision_landmark" => "not-landmark",
          "tribunal_decision_reference_number" => "1234567890",
          "tribunal_decision_sub_categories" => %w[section-95-destitution],
        }
      end
    end
  end

  factory :business_finance_support_scheme, parent: :document do
    base_path { "/business-finance-support/example-document" }
    document_type { "business_finance_support_scheme" }

    transient do
      default_metadata do
        {
          "business_sizes" => %w[under-10 between-10-and-249],
          "business_stages" => %w[start-up],
          "continuation_link" => "https://www.gov.uk",
          "industries" => %w[information-technology-digital-and-creative],
          "regions" => %w[northern-ireland],
          "types_of_support" => %w[finance],
          "will_continue_on" => "on GOV.UK",
        }
      end
    end
  end

  factory :cma_case, parent: :document do
    base_path { "/cma-cases/example-document" }
    document_type { "cma_case" }

    transient do
      default_metadata do
        {
          "opened_date" => "2014-01-01",
          "closed_date" => "2015-01-01",
          "case_type" => "ca98-and-civil-cartels",
          "case_state" => "closed",
          "market_sector" => %w[energy],
          "outcome_type" => "ca98-no-grounds-for-action-non-infringement",
        }
      end
    end
  end

  factory :countryside_stewardship_grant, parent: :document do
    base_path { "/countryside-stewardship-grants/example-document" }
    document_type { "countryside_stewardship_grant" }

    transient do
      default_metadata do
        {
          "grant_type" => "option",
          "land_use" => %w[priority-habitats trees-non-woodland uplands],
          "tiers_or_standalone_items" => %w[higher-tier],
          "funding_amount" => %w[201-to-300],
        }
      end
    end
  end

  factory :dfid_research_output, parent: :document do
    base_path { "/dfid-research-outputs/example-document" }
    document_type { "dfid_research_output" }

    transient do
      default_metadata do
        {
          "dfid_document_type" => "book_chapter",
          "country" => %w[GB],
          "dfid_authors" => ["Mr. Potato Head", "Mrs. Potato Head"],
          "dfid_theme" => %w[infrastructure],
          "first_published_at" => "2016-04-28",
          "bulk_published" => true,
        }
      end
    end
  end

  factory :research_for_development_output, parent: :document do
    base_path { "/research-for-development-outputs/example-document" }
    document_type { "research_for_development_output" }

    transient do
      default_metadata do
        {
          "research_document_type" => "book_chapter",
          "country" => %w[GB],
          "authors" => ["Mr. Potato Head", "Mrs. Potato Head"],
          "theme" => %w[infrastructure],
          "first_published_at" => "2016-04-28",
          "bulk_published" => true,
        }
      end
    end
  end

  factory :drug_safety_update, parent: :document do
    base_path { "/drug-safety-update/example-document" }
    document_type { "drug_safety_update" }

    transient do
      default_metadata do
        {
          "therapeutic_area" => %w[cancer haematology immunosuppression-transplantation],
        }
      end
    end
  end

  factory :employment_appeal_tribunal_decision, parent: :document do
    base_path { "/employment-appeal-tribunal-decisions/example-document" }
    document_type { "employment_appeal_tribunal_decision" }

    transient do
      default_metadata do
        {
          "tribunal_decision_categories" => %w[age-discrimination],
          "tribunal_decision_decision_date" => "2015-07-30",
          "tribunal_decision_landmark" => "landmark",
          "tribunal_decision_sub_categories" => %w[contract-of-employment-apprenticeship],
          "hidden_indexable_content" => "???",
        }
      end
    end
  end

  factory :employment_tribunal_decision, parent: :document do
    base_path { "/employment-tribunal-decisions/example-document" }
    document_type { "employment_tribunal_decision" }

    transient do
      default_metadata do
        {
          "tribunal_decision_categories" => %w[age-discrimination],
          "tribunal_decision_country" => "england-and-wales",
          "tribunal_decision_decision_date" => "2015-07-30",
          "hidden_indexable_content" => "???",
        }
      end
    end
  end

  factory :esi_fund, parent: :document do
    base_path { "/european-structural-investment-funds/example-document" }
    document_type { "esi_fund" }

    transient do
      default_metadata do
        {
          "closing_date" => "2016-01-01",
          "fund_state" => "open",
          "fund_type" => %w[business-support],
          "location" => %w[south-west],
          "funding_source" => %w[european-regional-development-fund],
        }
      end
    end
  end

  factory :international_development_fund, parent: :document do
    base_path { "/international-development-funding/example-document" }
    document_type { "international_development_fund" }

    transient do
      default_metadata do
        {
          "fund_state" => "open",
          "location" => %w[ghana],
          "development_sector" => %w[climate-change],
          "eligible_entities" => %w[non-governmental-organisations],
          "value_of_funding" => %w[up-to-100000],
        }
      end
    end
  end

  factory :maib_report, parent: :document do
    base_path { "/maib-reports/example-document" }
    document_type { "maib_report" }

    transient do
      default_metadata do
        {
          "date_of_occurrence" => "2015-10-10",
          "report_type" => "investigation-report",
          "vessel_type" => %w[merchant-vessel-100-gross-tons-or-over],
        }
      end
    end
  end

  factory :medical_safety_alert, parent: :document do
    base_path { "/drug-device-alerts/example-document" }
    document_type { "medical_safety_alert" }

    transient do
      default_metadata do
        {
          "alert_type" => "company-led-drugs",
          "issued_date" => "2016-02-01",
          "medical_specialism" => %w[anaesthetics cardiology],
        }
      end
    end
  end

  factory :raib_report, parent: :document do
    base_path { "/raib-reports/example-document" }
    document_type { "raib_report" }

    transient do
      default_metadata do
        {
          "date_of_occurrence" => "2015-10-10",
          "report_type" => "investigation-report",
          "railway_type" => %w[heavy-rail],
        }
      end
    end
  end

  factory :residential_property_tribunal_decision, parent: :document do
    base_path { "/residential-property-tribunal-decisions/example-document" }
    document_type { "residential_property_tribunal_decision" }

    transient do
      default_metadata do
        {
          "tribunal_decision_category" => "leasehold-disputes-management",
          "tribunal_decision_sub_category" => "leasehold-disputes-management---appointment-of-manager",
          "tribunal_decision_decision_date" => "2018-01-17",
          "hidden_indexable_content" => "some hidden content",
        }
      end
    end
  end

  factory :statutory_instrument, parent: :document do
    base_path { "/eu-withdrawal-act-2018-statutory-instruments/example-document" }
    document_type { "statutory_instrument" }

    transient do
      default_metadata do
        {
          "laid_date" => "2018-01-01",
          "sift_end_date" => "2018-01-05",
          "sifting_status" => "open",
          "subject" => %w[business],
        }
      end

      organisation_content_id { "6de6b795-9d30-4bd8-a257-ab9a6879e1ea" }
      primary_publishing_org_content_id { "d31d9806-2644-4023-be70-5376cae84a06" }
    end

    initialize_with do
      attributes.merge(
        links: {
          finder: [FinderSchema.new(document_type.pluralize).content_id],
          organisations: [organisation_content_id, primary_publishing_org_content_id],
          primary_publishing_organisation: [primary_publishing_org_content_id],
        },
      )
    end
  end

  factory :tax_tribunal_decision, parent: :document do
    base_path { "/tax-and-chancery-tribunal-decisions/example-document" }
    document_type { "tax_tribunal_decision" }

    transient do
      default_metadata do
        {
          "tribunal_decision_category" => "banking",
          "tribunal_decision_decision_date" => "2015-07-30",
          "hidden_indexable_content" => "???",
        }
      end
    end
  end

  factory :uk_market_conformity_assessment_body, parent: :document do
    base_path { "/uk_market_conformity_assessment_body/example-document" }
    document_type { "uk_market_conformity_assessment_body" }

    transient do
      default_metadata do
        {
          "updated_at" => "2019-04-10",
          "uk_market_conformity_assessment_body_number" => "AB 0000",
          "uk_market_conformity_assessment_body_type" => "approved-body",
          "uk_market_conformity_assessment_body_registered_office_location" => "united-kingdom",
          "uk_market_conformity_assessment_body_testing_locations" => %w[united-kingdom],
          "uk_market_conformity_assessment_body_website" => "www.example.com",
          "uk_market_conformity_assessment_body_email" => "info@example.com",
          "uk_market_conformity_assessment_body_phone" => "0800 000 000",
          "uk_market_conformity_assessment_body_legislative_area" => "explosives",
        }
      end
    end
  end

  factory :utaac_decision, parent: :document do
    base_path { "/administrative-appeals-tribunal-decisions/example-document" }
    document_type { "utaac_decision" }

    transient do
      default_metadata do
        {
          "tribunal_decision_categories" => ["Benefits for children"],
          "tribunal_decision_decision_date" => "2016-01-01",
          "tribunal_decision_judges" => %w[angus-r],
          "tribunal_decision_sub_categories" => %w[benefits-for-children-benefit-increases-for-children],
          "hidden_indexable_content" => "???",
        }
      end
    end
  end

  factory :my_document_type, parent: :document do
    base_path { "/base-path-for-my-document-type" }
    document_type { "my_document_type" }
  end

  factory :attachment_payload, class: Hash do
    content_id
    sequence(:url) do |n|
      "https://assets.digital.cabinet-office.gov.uk/media/513a0efbed915d425e000002/asylum-support-image-#{n}.jpg"
    end
    content_type { "application/jpeg" }
    title { "asylum report image title" }
    created_at { "2015-12-18T10:12:26+00:00" }
    updated_at { "2015-12-18T10:12:26+00:00" }

    initialize_with { attributes }
    to_create(&:deep_stringify_keys!)
  end
end
