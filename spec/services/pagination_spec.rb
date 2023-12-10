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

    it 'caps an absurd page number so the offset fits in a bigint' do
      expect(described_class.page(params: { page: '9' * 30 })).to eq(described_class::MAX_PAGE)
    end
  end

  describe '.max_per_page' do
    around do |example|
      original = ENV.fetch('EVENTS_MAX_PAGE_SIZE', nil)
      example.run
    ensure
      ENV['EVENTS_MAX_PAGE_SIZE'] = original
    end

    it 'reads EVENTS_MAX_PAGE_SIZE' do
      ENV['EVENTS_MAX_PAGE_SIZE'] = '25'

      expect(described_class.max_per_page).to eq(25)
    end

    it 'never drops below one row when the setting is zero or garbage' do
      %w[0 -4 abc].each do |value|
        ENV['EVENTS_MAX_PAGE_SIZE'] = value

        expect(described_class.per_page(params: { per_page: '10' })).to eq(1)
      end
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
