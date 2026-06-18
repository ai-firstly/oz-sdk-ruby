# frozen_string_literal: true

RSpec.describe Oz::Model do
  subject(:model) do
    described_class.new(
      'run_id' => 'abc',
      'state' => 'QUEUED',
      'at_capacity' => false,
      'config' => { 'model_id' => 'claude-sonnet-4', 'mcp_servers' => { 'github' => { 'warp_id' => 'x' } } },
      'artifacts' => [{ 'artifact_type' => 'PLAN' }, { 'artifact_type' => 'FILE' }]
    )
  end

  it 'reads attributes as methods' do
    expect(model.run_id).to eq('abc')
    expect(model.state).to eq('QUEUED')
  end

  it 'reads attributes with []' do
    expect(model['run_id']).to eq('abc')
    expect(model[:run_id]).to eq('abc')
  end

  it 'returns nil for unknown attributes' do
    expect(model.nonexistent).to be_nil
  end

  it 'supports boolean predicate methods' do
    expect(model.at_capacity?).to be(false)
    expect(model.run_id?).to be(true)
    expect(model.missing?).to be(false)
  end

  it 'wraps nested hashes recursively' do
    expect(model.config).to be_a(described_class)
    expect(model.config.model_id).to eq('claude-sonnet-4')
    expect(model.config.mcp_servers.github.warp_id).to eq('x')
  end

  it 'wraps arrays of hashes recursively' do
    expect(model.artifacts).to all(be_a(described_class))
    expect(model.artifacts.map(&:artifact_type)).to eq(%w[PLAN FILE])
  end

  it 'reports key presence' do
    expect(model.key?('run_id')).to be(true)
    expect(model.key?(:at_capacity)).to be(true)
    expect(model.key?('nope')).to be(false)
  end

  it 'lists keys' do
    expect(model.keys).to include('run_id', 'state', 'config')
  end

  it 'converts back to a plain hash deeply' do
    hash = model.to_h
    expect(hash).to be_a(Hash)
    expect(hash['config']).to eq('model_id' => 'claude-sonnet-4', 'mcp_servers' => { 'github' => { 'warp_id' => 'x' } })
    expect(hash['artifacts']).to eq([{ 'artifact_type' => 'PLAN' }, { 'artifact_type' => 'FILE' }])
  end

  it 'is enumerable over key/value pairs' do
    expect(model.to_a).to include(%w[run_id abc])
  end

  it 'responds_to known attributes and predicates' do
    expect(model).to respond_to(:run_id)
    expect(model).to respond_to(:at_capacity?)
  end

  it 'compares by content' do
    expect(described_class.new('a' => 1)).to eq(described_class.new('a' => 1))
    expect(described_class.new('a' => 1)).not_to eq(described_class.new('a' => 2))
  end

  describe '.build' do
    it 'passes through scalars' do
      expect(described_class.build('x')).to eq('x')
      expect(described_class.build(5)).to eq(5)
      expect(described_class.build(nil)).to be_nil
    end

    it 'maps arrays' do
      built = described_class.build([{ 'a' => 1 }, 'scalar'])
      expect(built[0]).to be_a(described_class)
      expect(built[1]).to eq('scalar')
    end

    it 'returns an existing model unchanged' do
      expect(described_class.build(model)).to be(model)
    end
  end

  it 'has a readable inspect string' do
    expect(model.inspect).to include('Oz::Model', 'run_id=')
  end
end
