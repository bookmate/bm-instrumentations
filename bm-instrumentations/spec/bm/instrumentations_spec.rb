# frozen_string_literal: true

require 'bm/instrumentations'

RSpec.describe BM::Instrumentations do
  it 'has VERSION' do
    expect(described_class::VERSION).to eq('0.1.0')
  end
end
