# frozen_string_literal: true

require 'bm/instrumentations'

RSpec.describe BM::Instrumentations::Process::Linux::ProcStatus do
  subject(:proc_status) { described_class.new(status_file: status_file.path) }

  let(:status_file) { Tempfile.new('status').tap(&:close) }

  after { status_file.unlink }

  describe '#rss_memory_bytes' do
    subject(:rss_memory_bytes) { proc_status.rss_memory_bytes }

    context 'when successfully read status file' do
      let(:source) { File.expand_path('./status.txt', __dir__) }

      before do
        File.open(status_file.path, 'wb') { |dst| dst.write File.open(source, 'rb', &:read) }
      end

      it 'returns RSS memory bytes' do
        expect(proc_status).to be_available
        expect(rss_memory_bytes).to eq(1_089_589_248)
      end
    end

    context 'when unable to find VmRSS fragment' do
      before do
        File.open(status_file.path, 'w') do |f|
          f.write('Foo Bar')
        end
      end

      it 'returns a zero' do
        expect(rss_memory_bytes).to be_zero
      end
    end

    context 'when unable to match RSS bytes' do
      before do
        File.open(status_file.path, 'w') do |f|
          f.write('VmRSS:')
        end
      end

      it 'returns a zero' do
        expect(rss_memory_bytes).to be_zero
      end
    end

    context 'with real status file (on Linux)' do
      subject(:proc_status) { described_class.new }

      before do
        skip('Linux only') unless RUBY_PLATFORM.include?('linux')
      end

      it 'returns the current process RSS memory bytes' do
        expect(rss_memory_bytes).to be_positive
      end
    end
  end
end
