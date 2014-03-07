require 'dependency_container'
require 'securerandom'
require 'builders/specialist_document_builder'
require 'gds_api/panopticon'
require "specialist_document_attachment_processor"

SpecialistPublisherWiring = DependencyContainer.new do
  define_instance(:specialist_document_editions) { SpecialistDocumentEdition }
  define_instance(:artefacts) { Artefact }
  define_instance(:panopticon_mappings) { PanopticonMapping }
  define_singleton(:panopticon_api) do
    GdsApi::Panopticon.new(Plek.current.find("panopticon"), PANOPTICON_API_CREDENTIALS)
  end

  define_singleton(:specialist_document_factory) {
    ->(*args) {
      SpecialistDocument.new(get(:slug_generator), get(:edition_factory), *args)
    }
  }

  define_singleton(:specialist_document_repository) do
    build_with_dependencies(SpecialistDocumentRepository)
  end

  define_singleton(:id_generator) { SecureRandom.method(:uuid) }

  define_singleton(:edition_factory) { SpecialistDocumentEdition.method(:new) }
  define_singleton(:attachment_factory) { Attachment.method(:new) }

  define_factory(:specialist_document_builder) {
    build_with_dependencies(SpecialistDocumentBuilder)
  }

  define_instance(:slug_generator) { SlugGenerator }

  define_singleton(:specialist_document_renderer) {
    ->(document) {
      Govspeak::Document.new(
        SpecialistDocumentAttachmentProcessor.new(document).body
      ).to_html
    }
  }
end
