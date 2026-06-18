# frozen_string_literal: true

# Manage agent identities (team-owned execution principals).
#
#   WARP_API_KEY=sk-... ruby examples/identities.rb

require 'oz'

client = Oz::Client.new

identity = client.agent.identities.create(
  name: 'ci-bot',
  description: 'Runs nightly maintenance tasks',
  skills: ['warpdotdev/warp-server:.claude/skills/deploy/SKILL.md']
)
puts "Created identity #{identity.uid}"

puts 'All identities:'
client.agent.identities.list.agents.each do |agent|
  puts "  #{agent.uid} #{agent.name}"
end

client.agent.identities.update(identity.uid, description: 'Updated description')
puts 'Updated.'

# Use the identity as the execution principal for a team-owned run:
run = client.agent.run(
  prompt: 'Run the nightly checks',
  team: true,
  agent_identity_uid: identity.uid
)
puts "Started run #{run.run_id} as identity #{identity.uid}"

client.agent.identities.delete(identity.uid)
puts 'Deleted identity.'
