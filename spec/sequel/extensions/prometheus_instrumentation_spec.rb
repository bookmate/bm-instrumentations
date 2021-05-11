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
  let(:db_name) { URI(database_url).path[1..] }

  after { db.disconnect }

  context 'when registered twice' do
    subject(:second_db) do
      Sequel.connect(database_url).tap do |db|
        db.extension(:prometheus_instrumentation)
        db.prometheus_registry = registry
      end
    end

    after { second_db.disconnect }

    it 'shares same metrics' do
      expect(second_db.metrics_collection.query_duration_seconds).to \
        eq(db.metrics_collection.query_duration_seconds)

      expect(second_db.metrics_collection.queries_total).to \
        eq(db.metrics_collection.queries_total)
    end
  end

  it 'creates a database with prometheus instrumentations' do
    expect(db).to be_kind_of(Sequel::Database)
    expect(db.method(:log_connection_yield).source_location[0]).to be_end_with('prometheus_instrumentation.rb')
  end

  it 'registers metrics in registry' do
    db

    expect(registry.get(:sequel_queries_total)).to be_kind_of(Prometheus::Client::Counter)
    expect(registry.get(:sequel_query_duration_seconds)).to be_kind_of(Prometheus::Client::Histogram)
  end

  describe 'collect metrics' do
    let(:labels) { { database: db_name, query: 'select', status: 'success' } }

    before do
      expect(db.fetch('select 1 + 1').first!).to eq('1 + 1': 2)
    end

    it_behaves_like 'increments a counter', :sequel_queries_total
    it_behaves_like 'fills a histogram buckets', :sequel_query_duration_seconds
  end

  describe 'collect metrics', 'when an exception has raised' do
    let(:labels) { { database: db_name, query: 'select', status: 'failure' } }

    before do
      expect { db.fetch('select _missing_ from _missing_').first }.to raise_error(Sequel::DatabaseError)
    end

    it_behaves_like 'increments a counter', :sequel_queries_total
    it_behaves_like 'fills a histogram buckets', :sequel_query_duration_seconds
  end
end
