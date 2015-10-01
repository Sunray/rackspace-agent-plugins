#!/usr/bin/env ruby

# freeradius-stats.rb
# Rackspace Cloud Monitoring Plugin to retrieve freeradius statistics 

# (c) 2015 Sunray
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


#
# This plugin monitors statistics using the the Freeradius built-in `radclient`
# command. The following metrics are collected:
#
#   service_status
#   service_last_restarted
#   access_requests
#   access_accepts
#   access_rejects
#   access_challenges
#   auth_responses
#   duplicate_requests
#   malformed_requests
#   invalid_requests
#   dropped_requests
#   unknown_types
#


#
# Usage:
#
#  freeradius-stats.rb [-h HOSTNAME -p PORT] -s SECRET
#     -h, --hostname HOSTNAME          The freeradius hostname. If not specified, will use: 127.0.0.1
#     -p, --port PORT                  The freeradius status port. If not specified, will use: 18121
#     -s, --secret SECRET              The secret as defined via the "secret" key within the client admin block.
#         --help                       Show this message
#
#


########################################################################################################################


# If the plugin fails in any way, print why and exit nonzero.
def fail(status="Unknown failure")
  puts "status #{status}"
  exit 1
end

# Store metrics in a hash and don't print them until we've completed
def metric(name,type,value)
  @metrics[name] = {
    :type => type,
    :value => value
  }
end

# Once the script has succeeded without errors, print metrics lines.
def output_success
  @metrics.each do |name,v|
    puts "metric #{name} #{v[:type]} #{v[:value]}"
  end
end


########################################################################################################################


begin
  require 'optparse'
rescue
  fail "Failed to load required ruby gems!"
end

@metrics = {}
options = {}

args = ARGV.dup

OptionParser.new do |o|
  o.banner = "Usage: #{$0} [-h HOSTNAME -p PORT] -s SECRET"
  o.on('-h', '--hostname HOSTNAME', 'The freeradius hostname. If not specified, will use: 127.0.0.1') do |h| 
    options[:hostname] = h
  end
  o.on('-p', '--port PORT', 'The freeradius status port. If not specified, will use: 18121') do |p| 
    options[:port] = p
  end
  o.on('-s', '--secret SECRET', 'The secret as defined via the "secret" key within the client admin block.') do |s| 
    options[:secret] = s
  end
  o.on_tail('-h', '--help', 'Show this message') { puts o; exit }
  o.parse!(args)
end


# Validate
fail "You must specify a freeradius admin password via the -u or --password options." if options[:secret].nil?

@hostname = options[:hostname] || '127.0.0.1'
@port = options[:port] || '18121'



#
# Service Status
#

output = `systemctl status radiusd 2>&1`
if !$?.success?
  
  fail("Radiusd service is not running.")

else

  # Filter out lines that are not important
  lines = output.split(/\n/)
  lines = lines.grep(Regexp.new(/Active:/))
  
  matches = /Active:\s(.+)\s+since\s+(.*)/.match(lines[0])
  fail("Freeradius service not running: #{matches[0]}") unless "active (running)" === matches[1]
  
  metric("service_status", "string", matches[1])
  metric("service_last_restarted", "string", matches[2])

end


#
# Stats
#

output = `echo "Message-Authenticator = 0x00, FreeRADIUS-Statistics-Type = 1, Response-Packet-Type = Access-Accept" | radclient -x -r 1 #{@hostname}:#{@port} status #{options[:secret]} 2>&1`
if !$?.success? or output =~ /no response/i
  
  fail("Could not connect to Freeradius status server @ #{@hostname}:#{@port}.\n\nCommand Result:\n\n#{output}")

else

  print output
  lines = output.split(/\n/)
  
  # Filter out lines that are not important
  lines = lines.grep(Regexp.new(/FreeRADIUS-Total/))
  
  access_requests = lines[0].split(' = ')[1].to_i
  access_accepts = lines[1].split(' = ')[1].to_i
  access_rejects = lines[2].split(' = ')[1].to_i
  access_challenges = lines[3].split(' = ')[1].to_i
  auth_responses = lines[4].split(' = ')[1].to_i
  duplicate_requests = lines[5].split(' = ')[1].to_i
  malformed_requests = lines[6].split(' = ')[1].to_i
  invalid_requests = lines[7].split(' = ')[1].to_i
  dropped_requests = lines[8].split(' = ')[1].to_i
  unknown_types = lines[9].split(' = ')[1].to_i
  
  metric("access_requests", "int", access_requests)
  metric("access_accepts", "int", access_accepts)
  metric("access_rejects", "int", access_rejects)
  metric("access_challenges", "int", access_challenges)
  metric("auth_responses", "int", auth_responses)
  metric("duplicate_requests", "int", duplicate_requests)
  metric("malformed_requests", "int", malformed_requests)
  metric("invalid_requests", "int", invalid_requests)
  metric("dropped_requests", "int", dropped_requests)
  metric("unknown_types", "int", unknown_types)
  
end

output_success