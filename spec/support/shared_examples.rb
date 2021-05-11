# frozen_string_literal: true

RSpec.shared_examples 'increments a counter' do |counter, override_labels = nil|
  it "increments a #{counter}" do
    expect(counter_value(counter, override_labels || labels)).to eq(1.0)
  end
end

RSpec.shared_examples 'fills a histogram buckets' do |histogram|
  it "fills a #{histogram} buckets" do
    expected = { '+Inf' => 1.0 }
    expect(histogram_value(histogram, labels)).to include(expected)
  end
end

RSpec.shared_examples 'does not increment a counter' do |counter|
  it "does not increment a #{counter}" do
    expect(metric_values(counter)).to be_empty
  end
end

RSpec.shared_examples 'does not fill a histogram buckets' do |histogram|
  it "does not fill a #{histogram} buckets" do
    expect(metric_values(histogram)).to be_empty
  end
end
