# frozen_string_literal: true

RSpec.describe Oz::CursorPage do
  let(:resource) { instance_double(Oz::Resources::Runs) }

  def page(body, params: {})
    described_class.new(body, resource: resource, params: params)
  end

  it 'exposes wrapped items via data and enumeration' do
    p = page({ 'runs' => [{ 'run_id' => 'a' }, { 'run_id' => 'b' }] })
    expect(p.data).to all(be_a(Oz::Model))
    expect(p.map(&:run_id)).to eq(%w[a b])
    expect(p.size).to eq(2)
    expect(p).not_to be_empty
  end

  it 'handles an empty / missing body' do
    expect(page({}).data).to eq([])
    expect(page(nil)).to be_empty
  end

  it 'reports next page availability from page_info' do
    p = page({ 'runs' => [], 'page_info' => { 'has_next_page' => true, 'next_cursor' => 'c1' } })
    expect(p.has_next_page).to be(true)
    expect(p.next_cursor).to eq('c1')
    expect(p.next_page?).to be(true)
  end

  it 'has no next page when has_next_page is false' do
    p = page({ 'runs' => [], 'page_info' => { 'has_next_page' => false, 'next_cursor' => 'c1' } })
    expect(p.next_page?).to be(false)
  end

  it 'has no next page without a cursor' do
    expect(page({ 'runs' => [] }).next_page?).to be(false)
    expect(page({ 'runs' => [], 'page_info' => { 'next_cursor' => '' } }).next_page?).to be(false)
  end

  it 'fetches the next page reusing filters with the new cursor' do
    p = page({ 'runs' => [{ 'run_id' => 'a' }], 'page_info' => { 'next_cursor' => 'c2' } },
             params: { limit: 10, state: ['QUEUED'] })
    next_page = page({ 'runs' => [{ 'run_id' => 'b' }] })
    expect(resource).to receive(:list).with(limit: 10, state: ['QUEUED'], cursor: 'c2').and_return(next_page)
    expect(p.next_page).to be(next_page)
  end

  it 'raises when there is no next page' do
    expect { page({ 'runs' => [] }).next_page }.to raise_error(Oz::Error, /No next page/)
  end

  describe '#auto_paging_each' do
    it 'walks across pages lazily' do
      page1 = page({ 'runs' => [{ 'run_id' => 'a' }], 'page_info' => { 'next_cursor' => 'c2' } }, params: {})
      page2 = page({ 'runs' => [{ 'run_id' => 'b' }] })
      allow(resource).to receive(:list).with(cursor: 'c2').and_return(page2)

      ids = []
      page1.auto_paging_each { |run| ids << run.run_id }
      expect(ids).to eq(%w[a b])
    end

    it 'returns an enumerator without a block' do
      p = page({ 'runs' => [{ 'run_id' => 'a' }] })
      expect(p.auto_paging_each).to be_a(Enumerator)
    end
  end
end
