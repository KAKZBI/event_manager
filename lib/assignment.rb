
require 'csv'
require 'net/http'
require 'json'
require 'uri'
require 'erb'
require 'pry-byebug'
require 'ostruct'
require 'time'

def legislators_by_zipcode(zip) 
  api_key = File.read('lib/secret.key').strip
  url = "https://api.geocod.io/v1.7/geocode?q=#{zip}&fields=cd&api_key=#{api_key}"
  begin
    
    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)

    # 1. Dig down to the array of districts
    districts = data.dig('results', 0, 'fields', 'congressional_districts')# || []
    # 2. Get all legislators from all districts found for this zip
    # We use flat_map to get one clean list of people
    raw_legislators = districts.flat_map { |dist| dist['current_legislators'] }
    # 3. TRANSFORM: Turn those hashes into "Objects" the template understands
    raw_legislators.map do |leg|
      OpenStruct.new(
        name: "#{leg['bio']['first_name']} #{leg['bio']['last_name']}",
        urls: [leg['contact']['url']]
      )
    end

  rescue 
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "Event Manager Initialized!"

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

def clean_phone_number(number)
  clean_number = number.to_s.gsub(/\D/, "")
  if clean_number.length < 10 || clean_number.length > 11
      return  "0000000000"
  elsif clean_number.length == 10
    return clean_number
  elsif clean_number.length == 11
      return "0000000000" if clean_number[0] != "1"
      clean_number[1..-1]
  end
end

registration_hours = []
registration_days = []

contents = CSV.open('event_attendees.csv', 
headers: true,
header_converters: :symbol
)
contents.each do |row|
  # id = row[0]
  name = row[:first_name]
  regdate = row[:regdate]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
  phone = clean_phone_number(row[:homephone])
  time = Time.strptime(regdate, "%m/%d/%y %H:%M")
  registration_hours << time.hour
  registration_days << Date::DAYNAMES[time.wday]
  
end

# Output the Time Targeting Results
puts "\n--- Peak Registration Hours ---"

# sorts by the count in descending order
hours_tally = registration_hours.tally.sort_by { |hour, count| -count }

hours_tally.each do |hour, count|
  # formatting the hour to look like "14:00" for readability
  display_hour = hour.to_s.rjust(2, '0') 
  puts "#{display_hour}:00 -- #{count} attendees"
end


# Output the Day of the Week Results
puts "\n--- Peak Registration Days ---"

days_tally = registration_days.tally.sort_by { |day, count| -count }

days_tally.each do |day, count|
  puts "#{day} -- #{count} attendees"
end