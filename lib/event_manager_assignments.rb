require 'csv'
# require 'google/apis/civicinfo_v2'
# require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

# template_letter = File.read('form_letter.erb')
# erb_template = ERB.new template_letter

# Assignment: Clean Phone Numbers
def clean_phone_number(number)
  digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
   num_of_digits = 0
   number.each_char do |char|
   num_of_digits += 1 if digits.include?(char)
   end
   if num_of_digits < 10 || num_of_digits > 11
      return  "0000000000"
   elsif num_of_digits == 10
    return number
    elsif num_of_digits == 11
      num1 = 0
      for i in 0...number.length
        if digits.include?(number[i])
          num1 = number[i]
          break
        end
      end
      return "0000000000" if num1 != "1"
      return number if num1 == "1"
   end
end
#Assignment: Time Targeting
def add_date(regdate)
   
  year = "20" + regdate[6..7]
  regdate = regdate.gsub(regdate[6..7], year)
  time = Time.strptime(regdate, "%m/%d/%Y %H:%M")

  $registration_hours.push(time.hour) 
  $registration_wdays.push(Date::DAYNAMES[time.wday])
end
def get_peak(contents)
  #create an array containing each content's number of occurrences
  contents_peak = contents.reduce(Hash.new(0)) do |content, occurence|
    content[occurence] += 1
    content
  end
  #Transform it into a hash
  contents_obj = {}
  contents_peak.each do |content|
    contents_obj[content[1]] = [] unless contents_obj[content[1]]
    contents_obj[content[1]].push(content[0])
    # occurence
  end
  #Sort the contents in descending order
  contents_final_obj = {}
  contents_obj.keys.sort.reverse.each do |content|
    contents_final_obj[content] = contents_obj[content]
  end

  return contents_final_obj#[hours_final_obj.keys[0]]
end

$registration_hours = []
$registration_wdays = []
puts "Assignment #1: Clean Phone Numbers"
contents.each do |row|
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  # legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone]) #Assignment 1
  # form_letter = erb_template.result(binding)
  # puts form_letter
  regdate = row[:regdate]
  add_date(regdate)

  p "#{name} -- #{zipcode} -- #{phone_number}"
end
puts
puts "Assignment #2: Time Targeting"
get_peak($registration_hours).each do |occurence, hours|
  if occurence == 1
     print "#{occurence} attendee registered at these hours: #{hours}\n"
  else 
    print "#{occurence} attendees registered at these hours: #{hours}\n"
  end
end

puts
puts 'Assignment #3: Day of the Week Targeting'
get_peak($registration_wdays).each do |occurence, days|
  if occurence == 1
     print "#{occurence} attendee registered on these days: #{days}\n"
  else 
    print "#{occurence} attendees registered on these days: #{days}\n"
  end
end