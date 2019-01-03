#!/usr/bin/env ruby

require 'optparse'
require 'pp'
require 'date'
require 'active_support/core_ext/time'

class Time
  def to_str(zone, iso8601=false)
    if iso8601
      # self.in_time_zone(zone).strftime("%Y-%m-%dT%H:%M:%SZ")
      self.in_time_zone(zone).to_formatted_s(:iso8601)
    else
      # self.in_time_zone(zone).strftime("%A, %Y-%m-%d %H:%M:%S %Z %z")
      self.in_time_zone(zone).to_formatted_s(:rfc822)
    end
  end

  def to_hash(zone)
    {
      tz: zone,
      rfc822: self.to_str(zone),
      iso8601: self.to_str(zone, true)
    }
  end
end

def usage
  puts @opt_parser
  exit 1
end

def print_header(columns)
  puts "| #{ columns.map { |_,g| g[:label].ljust(g[:width]) }.join(' | ') } |"
end

def print_divider(columns)
  puts "+-#{ columns.map { |_,g| "-"*g[:width] }.join("-+-") }-+"
end

def print_line(columns, h)
  str = h.keys.map { |k| h[k].ljust(columns[k][:width]) }.join(" | ")
  puts "| #{str} |"
end

@datetime = DateTime.now.to_s
@ffset = nil

@opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options]"
  opts.on('-s', '--string [datetime]', String, 'Input DateTime String') do |d|
    @datetime = d
  end
  opts.on('-o', '--offset [(-)seconds]', String, 'Time Adjustment (in seconds)' ) do |os|
    @offset = os
  end
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
  opts.parse!
end

SYD = 'Australia/Sydney'
LAX = 'US/Pacific'
UTC = 'UTC'
NYC = 'US/Eastern'
ZRH = 'Europe/Zurich'
HND = 'Asia/Tokyo'

time = DateTime.parse(@datetime).to_time

if @offset
  if @offset.include? '-'
    time -= @offset.gsub(/[^\d+]/,'').to_i
  else
    time += @offset.to_i
  end
  puts "Offset=#{@offset}(seconds)"
  puts
end

col_labels = { tz: "TZ", rfc822: "RFC822", iso8601: "ISO8601" }

a1 = [ time.to_hash(UTC), time.to_hash(LAX), time.to_hash(SYD) ]
a2 = [ time.to_hash(NYC), time.to_hash(ZRH), time.to_hash(HND) ]

columns = col_labels.each_with_object({}) do |(col,label),h|
  h[col] = { label: label, width: [a1.map { |g| g[col].size }.max, label.size].max }
end

# print table
print_divider(columns)
print_header(columns)
print_divider(columns)
a1.each { |h| print_line(columns, h) }
print_divider(columns)
a2.each { |h| print_line(columns, h) }
print_divider(columns)
