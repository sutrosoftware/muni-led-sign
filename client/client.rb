#!/usr/bin/ruby

require 'optparse'

require_relative 'lib'

font = muni_sign_font(File.join(File.dirname(__FILE__), 'font'))

options = {
    :update_interval => 30,
}

ARGV << "--help" if ARGV.length < 3

OptionParser.new do |opts|
  opts.banner = "Usage: client.rb"
  # Required
  opts.on('--route [route]', "Route name or number") { |v| options[:route] = v }
  opts.on('--dir [outbound|inbound]', "Route direction") { |v| options[:dir] = v }
  opts.on('--stop [stop]', "Stop name or ID to watch") { |v| options[:stop] = v }
  # Optional
  opts.on('--update-interval [seconds]', Integer, "Sign updates per second (default 30)") { |v| options[:update_interval] = v }
  opts.on('--dark-file [filename]', "Turn off the sign instead of updating, if filename exists") { |v| options[:dark_file] = v }
end.parse!


# Returns hash of predictions for this stop in UTC times for all routes.  Keys
# are route names, and values are arrays of predictions for that route at this
# stop.
def get_stop_arrivals(route, direction, stop)
  raise unless (route and direction and stop)
  r = Muni::Route.find(route)
  s = r.direction_at(direction).stop_at(stop)
  retval = {}
  retval[r['title']] = s.predictions
  retval
end

# Convert from Nextbus format to what it actually displayed on a minu sign.
# Ordered list of regexp -> string pairs.  The first regexp to match a
# prediction's dirTag field replaces the route name with the string.
ROUTE_FIXUP_MAP = [
    [/^KT.*OB/, 'K-Ingleside'],
    [/^KT.*IBMTME/, 'T-Metro East Garage'],
    # Let's all all inbound KT-s like this.
    [/^KT.*IB/, 'T-Third Street'],
]

def fixup_route_name(route_name, prediction)
  # For now, just truncate, except for one thing.
  unstripped_result = route_name
  ROUTE_FIXUP_MAP.each do |regex, fixup|
    if regex =~ prediction.dirTag
      unstripped_result = fixup
      break
    end
  end
  # Strip result
  unstripped_result.slice(0, 18)
end

def muni_time(time)
  distance = time - Time.now
  if distance > 60
    "#{(distance / 60).to_i} min"
  elsif distance < -10
    # Not really useful.
    "#{((-distance) / 60).to_i} min ago"
  else
    # Finally!  It took that damn train like forever!
    "Arriving"
  end
end

def update_sign(font, options)
  arrival_times = get_stop_arrivals(options[:route], options[:dir], options[:stop])
  # Only debugging:
  #  $stderr.puts arrival_times.inspect
  texts_for_sign = []
  arrival_times_text = arrival_times.each do |route, predictions|
    # Show first two predictions
    prediction_text = predictions.slice(0, 2).map{|p| muni_time(p.time)}.join(' & ')
    unless prediction_text.empty?
      # Fixup route name.
      route_name = fixup_route_name(route, predictions[0])
      texts_for_sign << font.render_multiline([route_name, prediction_text], 8, :ignore_shift_h => true, :distance => 0, :fixed_width => LED_Sign::SCREEN_WIDTH)
    end
  end
  if texts_for_sign && !texts_for_sign.empty?
    text_for_sign = texts_for_sign.map(&:zero_one).join("\n\n")
  else
    # Empty predictions array: this may be just nighttime.
    text_for_sign = font.render_multiline(["No routes", "until next morning."], 8, :ignore_shift_h => true, :distance => 0, :fixed_width => LED_Sign::SCREEN_WIDTH).zero_one
  end
  LED_Sign.pic(text_for_sign)
#  puts text_for_sign
#  $stdout.flush
end

while true
  begin
    darken_if_necessary(options) or update_sign(font, options)
  rescue => e
    $stderr.puts "Well, we continue despite this error: #{e}\n#{e.backtrace.join("\n")}"
  end
  sleep(options[:update_interval])
end

