#!/opt/puppetlabs/puppet/bin/ruby

require 'json'

params = JSON.parse(STDIN.read)

begin
  result = params['hash_data'].to_json
  json.dump(result, sys.stdout)
rescue
  exitcode = 1
  puts "Failed to convert to JSON"
end