# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pagination do
  describe '.per_page' do
    it 'falls back to the default' do
      expect(described_class.per_page(params: {})).to eq(described_class::DEFAULT_PER_PAGE)
    end

    it 'honours a sensible request' do
      expect(described_class.per_page(params: { per_page: '7' })).to eq(7)
    end

    it 'caps an oversized request' do
      expect(described_class.per_page(params: { per_page: '5000' })).to eq(described_class.max_per_page)
    end

    it 'refuses a zero or negative page size' do
      expect(described_class.per_page(params: { per_page: '0' })).to eq(1)
      expect(described_class.per_page(params: { per_page: '-3' })).to eq(1)
    end
  end

  describe '.page' do
    it 'defaults to the first page' do
      expect(described_class.page(params: {})).to eq(1)
    end

    it 'clamps nonsense to the first page' do
      expect(described_class.page(params: { page: '-2' })).to eq(1)
      expect(described_class.page(params: { page: 'banana' })).to eq(1)
    end
  end

  describe '.apply and .meta' do
    before { create_list(:event, 7) }

    it 'slices the scope' do
      page_two = described_class.apply(Event.chronological, params: { page: '2', per_page: '3' })

      expect(page_two.map(&:id)).to eq(Event.chronological.pluck(:id)[3, 3])
    end

    it 'reports the number of pages' do
      expect(described_class.meta(Event.all, params: { per_page: '3' }))
        .to include(total_count: 7, total_pages: 3, per_page: 3, page: 1)
    end

    it 'reports one page when there is nothing to show' do
      Event.delete_all

      expect(described_class.meta(Event.all, params: {})[:total_pages]).to eq(1)
    end
  end
end
