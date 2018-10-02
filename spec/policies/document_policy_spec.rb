require 'spec_helper'

RSpec.describe DocumentPolicy do
  class TestDocument < Document
    cattr_accessor :schema_organisations
    cattr_accessor :schema_editing_organisations
  end

  let(:allowed_organisation_id) { 'department-of-serious-business' }
  let(:allowed_editing_organisation_id) { 'hm-serious-business-countersigners' }
  let(:not_allowed_organisation_id) { 'ministry-of-funk' }
  let(:gds_editor) { User.new(permissions: %w(signin gds_editor)) }
  let(:departmental_editor) { User.new(permissions: %w(signin editor), organisation_content_id: allowed_organisation_id) }
  let(:other_departmental_editor) { User.new(permissions: %w(signin editor), organisation_content_id: allowed_editing_organisation_id) }
  let(:departmental_writer) { User.new(permissions: %w[signin], organisation_content_id: allowed_organisation_id) }
  let(:other_departmental_writer) { User.new(permissions: %w[signin], organisation_content_id: allowed_editing_organisation_id) }
  let(:document_type_editor) { User.new(permissions: %w[test_document_editor]) }

  let(:document_type) {
    TestDocument
  }

  let(:allowed_document_type) {
    document_type.tap do |dt|
      dt.schema_organisations = [allowed_organisation_id]
      dt.schema_editing_organisations = [allowed_editing_organisation_id]
    end
  }

  let(:not_allowed_document_type) {
    document_type.tap do |dt|
      dt.schema_organisations = [not_allowed_organisation_id]
    end
  }

  permissions :index?, :show?, :new?, :create?, :edit?, :update? do
    it 'denies access to users from another organisation' do
      expect(described_class).not_to permit(departmental_writer, not_allowed_document_type)
    end

    it 'grants access to users from the organisation to which the document belongs' do
      expect(described_class).to permit(departmental_writer, allowed_document_type)
    end

    it 'grants access to users from an editing organisation' do
      expect(described_class).to permit(other_departmental_writer, allowed_document_type)
    end

    it 'grants access to users with GDS Editor permissions' do
      expect(described_class).to permit(gds_editor, allowed_document_type)
    end

    it 'grants access to users with document type permissions' do
      expect(described_class).to permit(document_type_editor, allowed_document_type)
    end
  end

  permissions :publish?, :unpublish? do
    it 'denies access to users without editors permissions' do
      expect(described_class).not_to permit(departmental_writer, allowed_document_type)
    end

    it 'denies access to other users without editors permissions' do
      expect(described_class).not_to permit(other_departmental_writer, allowed_document_type)
    end

    it 'denies access to editors from another organisation' do
      expect(described_class).not_to permit(departmental_editor, not_allowed_document_type)
    end

    it 'grants access to editors from the organisation to which the document belongs' do
      expect(described_class).to permit(departmental_editor, allowed_document_type)
    end

    it 'grants access to editors from the organisation which can edit the document' do
      expect(described_class).to permit(other_departmental_editor, allowed_document_type)
    end

    it 'grants access to users with GDS Editor permissions' do
      expect(described_class).to permit(gds_editor, allowed_document_type)
    end

    it 'grants access to users with document type permissions' do
      expect(described_class).to permit(document_type_editor, allowed_document_type)
    end
  end
end
