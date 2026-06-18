# frozen_string_literal: true

# List recent runs, paging through all results.
#
#   WARP_API_KEY=sk-... ruby examples/list_runs.rb

require 'oz'

client = Oz::Client.new

# A single page:
page = client.agent.runs.list(limit: 25, sort_by: 'created_at', sort_order: 'desc')
puts "First page: #{page.size} run(s), more available: #{page.next_page?}"
page.each do |run|
  puts format('  %-38s %-11s %s', run.run_id, run.state, run.title)
end

puts
puts 'All runs created in the last 24h that are in progress:'

filtered = client.agent.runs.list(
  state: %w[INPROGRESS QUEUED],
  created_after: Time.now - (24 * 60 * 60)
)

count = 0
filtered.auto_paging_each do |run|
  count += 1
  puts "  #{run.run_id} #{run.state}"
end
puts "Total: #{count}"
