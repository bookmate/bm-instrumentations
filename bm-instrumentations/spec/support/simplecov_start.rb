# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'

  track_files 'lib/**/*.rb'

  if ENV['TEAMCITY_VERSION']
    at_exit do
      SimpleCov.result.format!

      puts <<~SUMMARY
        ##teamcity[blockOpened name='Code Coverage Summary']
        ##teamcity[buildStatisticValue key='CodeCoverageAbsLCovered' value='#{SimpleCov.result.covered_lines}']
        ##teamcity[buildStatisticValue key='CodeCoverageAbsLTotal' value='#{SimpleCov.result.total_lines}']
        ##teamcity[blockClosed name='Code Coverage Summary']
      SUMMARY
    end
  end
end
