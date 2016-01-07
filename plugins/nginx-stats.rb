#!/usr/bin/env ruby

# nginx-stats.rb
# Rackspace Cloud Monitoring Plugin to retrieve Nginx statistics

# (c) 2016 Sunray
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
# This plugin monitors statistics using the the built-in "stub-status" functionality.
# The following metrics are collected.
#
#   service_status
#   service_last_restarted
#   connections
#   accepts
#   handled
#   requests
#   reading
#   writing
#   waiting
#


#
# Usage:
#
#  nginx-stats.rb [-p PATH]
#     -p, --path NGINX_STUB_PATH       The path to pull the nginx stubs from. If not specified, will use: http://127.0.0.1/nginx_status
#         --help                       Show this message
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
  o.banner = "Usage: #{$0} [-p PATH]"
  o.on('-p', '--path NGINX_STUB_PATH', 'The path to pull the nginx stubs from. If not specified, will use: http://127.0.0.1/nginx_status') do |p| 
    options[:path] = p
  end
  o.on_tail('-h', '--help', 'Show this message') { puts o; exit }
  o.parse!(args)
end


@path = options[:path] || 'http://127.0.0.1/nginx_status'



#
# Service Status
#

output = `systemctl status nginx 2>&1`
if !$?.success?
  
  fail("Nginx service is not running.")

else

  # Filter out lines that are not important
  lines = output.split(/\n/)
  lines = lines.grep(Regexp.new(/Active:/))
  
  matches = /Active:\s(.+)\s+since\s+(.*)/.match(lines[0])
  fail("Nginx service not running: #{matches[0]}") unless "active (running)" === matches[1]
  
  metric("service_status", "string", matches[1])
  metric("service_last_restarted", "string", matches[2])

end



#
# Nginx Stats
#

output = `curl -s --max-time 10 #{@path} 2>&1`
if !$?.success? or output !~ /Active connections:/
  
  fail("Could not connect to Nginx status server @ #{@path}.\n\nCommand Result:\n\n#{output}")

else

  print output
  lines = output.split(/\n/)
  
  connectionLines = lines.grep(Regexp.new(/Active connection/))
  connections = connectionLines[0].split(':')[1].to_i
  metric("connections", "int", connections)
    
  server_requests = lines[2].strip!.split(' ')
  metric("accepts", "int", server_requests[0].to_i)
  metric("handled", "int", server_requests[1].to_i)
  metric("requests", "int", server_requests[2].to_i)
  
  status_requests = /Reading: (\d+) Writing: (\d+) Waiting: (\d+)/.match(lines[3]) 
  metric("reading", "int", status_requests.captures[0].to_i)
  metric("writing", "int", status_requests.captures[1].to_i)
  metric("waiting", "int", status_requests.captures[2].to_i)

end

output_success