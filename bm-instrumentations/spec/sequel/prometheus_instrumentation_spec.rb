# frozen_string_literal: true

require 'sequel'
require 'uri'

RSpec.describe 'Sequel::Extensions::PrometheusInstrumentation' do
  subject(:db) do
    Sequel.connect(database_url).tap do |db|
      db.extension(:prometheus_instrumentation)
      db.prometheus_registry = registry
    end
  end

  let(:database_url) { ENV.fetch('DATABASE_URL', 'mysql2://root@127.0.0.1:3306/mysql') }
  let(:registry) { Prometheus::Client::Registry.new }
  let(:db_name) { URI(database_url).path[1..-1] }

  it 'creates a database with prometheus instrumentations' do
    expect(db).to be_kind_of(Sequel::Database)
    expect(db.method(:log_connection_yield).source_location[0]).to be_end_with('prometheus_instrumentation.rb')
  end

  it 'registers metrics in registry' do
    db

    expect(registry.get(:sequel_queries_total)).to be_kind_of(Prometheus::Client::Counter)
    expect(registry.get(:sequel_queries_duration_seconds)).to be_kind_of(Prometheus::Client::Histogram)
  end


  shared_examples 'increments a :sequel_queries_total' do
    it 'increments a :sequel_queries_total' do
      expect(counter(:sequel_queries_total, labels)).to eq(1.0)
    end
  end

  shared_examples 'fills a :sequel_queries_duration_seconds buckets' do
    it 'fills a :sequel_queries_duration_seconds buckets' do
      expected = { '+Inf' => 1.0 }
      histogram_labels = { database: labels[:database], query: labels[:query] }

      expect(histogram(:sequel_queries_duration_seconds, histogram_labels)).to include(expected)
    end
  end

  describe 'collect metrics', 'without any exceptions' do
    let(:labels) { { database: db_name, query: 'select', status: 'success' } }

    before do
      expect(db.fetch('select 1 + 1').first!).to eq('1 + 1': 2)
    end

    it_behaves_like 'increments a :sequel_queries_total'
    it_behaves_like 'fills a :sequel_queries_duration_seconds buckets'
  end

  describe 'collect metrics', 'when an exception has raised' do
    let(:labels) { { database: db_name, query: 'select', status: 'fail' } }

    before do
      expect { db.fetch('select _missing_ from _missing_').first }.to raise_error(Sequel::DatabaseError)
    end

    it_behaves_like 'increments a :sequel_queries_total'
    it_behaves_like 'fills a :sequel_queries_duration_seconds buckets'
  end

  # @return [Float]
  def counter(name, labels = {})
    registry.get(name)&.get(labels: labels) || 0.0
  end

  # @return [Hash<String, Float>]
  def histogram(name, labels = {})
    registry.get(name)&.get(labels: labels) || {}
  end
end
