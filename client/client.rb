#!/usr/bin/ruby

require 'optparse'

require_relative 'lib'

font = muni_sign_font(File.join(File.dirname(__FILE__), 'font'))

options = {
    :interval => 30,
    :offset => 60
}

op = OptionParser.new do |opts|
  opts.banner = "Usage: client.rb"
  opts.on('-r', '--route ROUTE', "Route name or number")
  opts.on('-d', '--direction DIR', ["outbound", "inbound"], "Route direction - inbound or outbound")
  opts.on('-s', '--stop STOP', "Stop name or ID to watch")
  opts.on('-i', '--interval SECONDS', Integer, "Sign updates per second (default 30)")
  opts.on('-o', '--offset SECONDS', Integer, "Decrease prediction times by this many seconds (default 60)")
  opts.on('-b', '--blankfile FILE', "Turn off the sign instead of updating, if FILE exists")
  opts.on('-c', '--configfile FILE', "Config file for multiple stops (format: route|dir|stop)")
#  puts opts
end

begin
  op.parse!(into: options)
rescue
  puts op
  exit
end

# Returns hash of predictions for this stop in UTC times for all routes.  Keys
# are route names, and values are arrays of predictions for that route at this
# stop.
def get_stop_arrivals(route, direction, stop)
  raise unless (route and direction and stop)
  r = Muni::Route.find(route)
  s = r.direction_at(direction).stop_at(stop)
  suffix = (direction.eql? "inbound") ? " IB" : " OB"
  retval = {}
  retval[r['title'] + suffix] = s.predictions
  retval
end

# Convert from Nextbus format to what it actually displayed on a muni sign.
# Ordered list of regexp -> string pairs.  The first regexp to match a
# prediction's dirTag field replaces the route name with the string.
ROUTE_FIXUP_MAP = [
    [/^KT.*OB/, 'K-Ingleside'],
    [/^KT.*IBMTME/, 'T-Metro East Garage'],
    # Let's all all inbound KT-s like this.
    [/^KT.*IB/, 'T-Third Street'],
]

NOP = "No Prediction"

def fixup_route_name(route_name, prediction)
  # For now, just truncate, except for one thing.
  unstripped_result = route_name
  ROUTE_FIXUP_MAP.each do |regex, fixup|
    if regex =~ prediction.dirTag
      unstripped_result = fixup
      break
    end
  end
  # truncate result
  unstripped_result.slice(0, 18)
end

def muni_time(time, offset)
  distance = time - offset - Time.now
  if distance > 60
    "#{(distance / 60).to_i} min"
  elsif distance < -offset
    "Arrived"
  else
    "Arriving"
  end
end

def update_sign(font, allstops, offset)
  arrival_times = Hash.new
  allstops.each do |options|
    arrival_times.merge!(get_stop_arrivals(options[:route], options[:direction], options[:stop]))
  end
  # Only debugging:
  # puts arrival_times
  texts_for_sign = []
  arrival_times.each do |route, predictions|
    # Show first two predictions
    prediction_text = predictions.empty? ? NOP : predictions.slice(0, 2).map{|p|
      muni_time(p.time, offset)
    }.join(' & ')
    unless NOP.eql? prediction_text
      # Fixup route name.
      route = fixup_route_name(route, predictions[0])
    end
    texts_for_sign << font.render_multiline([route, prediction_text], 8, :ignore_shift_h => true, :distance => 0, :fixed_width => LED_Sign::SCREEN_WIDTH)
    #puts route
    #puts prediction_text
  end
  if texts_for_sign && !texts_for_sign.empty?
    text_for_sign = texts_for_sign.map(&:zero_one).join("\n\n")
  else
    # Empty predictions array: this may be just nighttime.
    text_for_sign = font.render_multiline(["No routes", "until next morning."], 8, :ignore_shift_h => true, :distance => 0, :fixed_width => LED_Sign::SCREEN_WIDTH).zero_one
  end
  LED_Sign.pic("0\n")
  LED_Sign.pic(text_for_sign)
#  puts text_for_sign
#  $stdout.flush
#  $stderr.flush
end

allstops = []

if options[:configfile] && File.exists?(options[:configfile])
  File.readlines(options[:configfile]).each do |line|
    r,d,s = line.strip.split('|')
    allstops << {:route => r, :direction => d, :stop => s}
  end
elsif !(options[:route] && options[:direction] && options[:stop])
  puts op
  exit
else
  allstops << options
end

while true
  begin
    darken_if_necessary(options) or update_sign(font, allstops, options[:offset])
  rescue => e
    $stderr.puts "Well, we continue despite this error: #{e}\n#{e.backtrace.join("\n")}"
  end
  sleep(options[:interval])
end

