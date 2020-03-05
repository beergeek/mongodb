#!/opt/puppetlabs/puppet/bin/ruby

require 'json'

params = JSON.parse(STDIN.read)

begin
  result = params['hash_data'].to_json
  puts result
  exitcode = 0
rescue
  exitcode = 1
  puts "Failed to convert to JSON"
end