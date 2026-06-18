# frozen_string_literal: true

# Create, inspect, pause/resume, and delete a scheduled agent.
#
#   WARP_API_KEY=sk-... ruby examples/schedules.rb

require 'oz'

client = Oz::Client.new

schedule = client.agent.schedules.create(
  cron_schedule: '0 9 * * *', # daily at 09:00 UTC
  name: 'nightly-dependency-check',
  prompt: 'Check for outdated dependencies and open a PR if needed',
  enabled: true
)
puts "Created schedule #{schedule.schedule_id} (#{schedule.name})"

puts 'All schedules:'
client.agent.schedules.list.schedules.each do |s|
  puts "  #{s.schedule_id} #{s.name} #{s.cron_schedule}"
end

client.agent.schedules.pause(schedule.schedule_id)
puts 'Paused.'

client.agent.schedules.resume(schedule.schedule_id)
puts 'Resumed.'

result = client.agent.schedules.delete(schedule.schedule_id)
puts "Deleted: #{result.success}"
