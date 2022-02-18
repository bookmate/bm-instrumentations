# frozen_string_literal: true

require 'bm/instrumentations'

RSpec.describe BM::Instrumentations::Process::Linux::ProcFD do
  subject(:proc_fd) { described_class.new(fd_dir: fd_dir) }

  let(:fd_dir) { __dir__ }

  describe '#count' do
    subject(:fd_count) { proc_fd.count }

    it 'returns a number of entries' do
      expect(fd_count).to be_positive
    end

    context 'with real fd directory (on Linux)' do
      subject(:proc_fd) { described_class.new }

      before do
        skip('Linux only') unless RUBY_PLATFORM.include?('linux')
      end

      it 'returns a number of entries' do
        expect(fd_count).to be_positive
      end
    end
  end
end
