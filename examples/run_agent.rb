# frozen_string_literal: true

# Run a cloud agent and poll until it finishes.
#
#   WARP_API_KEY=sk-... ruby examples/run_agent.rb "Fix the bug in auth.rb"
#
# Requires the gem to be installed, or run with `bundle exec` from the repo root.

require 'oz'

prompt = ARGV.first || 'Summarize the README and suggest improvements'

client = Oz::Client.new # reads WARP_API_KEY from the environment

run = client.agent.run(
  prompt: prompt,
  config: {
    # environment_id: "your-environment-id",
    model_id: 'claude-sonnet-4',
    name: 'sdk-example'
  }
)

puts "Started run #{run.run_id} (state: #{run.state})"

TERMINAL = %w[SUCCEEDED FAILED ERROR CANCELLED].freeze

loop do
  current = client.agent.runs.retrieve(run.run_id)
  puts "  #{Time.now.strftime('%H:%M:%S')} #{current.state}"
  break if TERMINAL.include?(current.state)

  sleep 5
end

final = client.agent.runs.retrieve(run.run_id)
puts "Finished: #{final.state}"
puts "Session: #{final.session_link}" if final.session_link
