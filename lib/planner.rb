require 'rubygems'
require 'nokogiri'
require 'httparty'
require 'set'
require 'YAML'
require 'geo_distance'
require 'fastercsv'
require 'regions'
require 'json'

require 'ebird_data'


if ARGV.size == 0
  p "Usage: ruby birdwatching_planner.rb lifelist.csv [landmarks_file=landmarks.yml] [plan_file=plan.csv] [locations_file=locations.json]"
  exit
end

lifelist_file = ARGV[0] || "./lifelist.csv"
landmarks_file = ARGV[1] || "landmarks.yml"
plan_file = ARGV[2] || "plan.csv"
locations_file = ARGV[3] || "locations.json"

# Foster City
my_location = { :lat => 37.553866, :long => -122.258992 }

# Las Vegas
my_location = { :lat => 37.0625, :long => -95.677068 }

# Sacramento
my_location = { :lat => 38.57642, :long => -121.497116 }

landmarks = Landmarks.from_file( landmarks_file )

location_map = Ebrd::Locations.map_from_file( locations_file )

use_grid = false
locations = []
if use_grid
  dlat=0.65
  dlong=0.85
  (-1..1).each do |la|
    (-1..1).each do |lo|
      locations << { :lat => my_location[:lat] + dlat * la , :long => my_location[:long] + dlong *lo }
    end
  end
else
  locations = [my_location]
end

radius = 50
observations = EBirdData::BirdObservations.all_near_locations( locations, radius )

max_distance = 120 
max_distance_miles = max_distance / 1.609344

observations.reject! {|loc|  Distance.geo_distance(loc["lat"], loc["lng"], my_location[:lat], my_location[:long]) > max_distance }
p "Got #{observations.size} observations in #{max_distance_miles} miles"


my_species = FasterCSV.open( lifelist_file, :headers => true ).map {|r| r["Species"]}
new_observations = observations.reject {|o| o["comName"].include?( "/" ) || o["comName"].include?(" sp.") || my_species.include?(o["comName"]) }

results = new_observations.map do |observation|
  lat = observation["lat"]
  long = observation["lng"]
  observation.dup.merge( "landmark" => Landmark.closest_landmark_name(landmarks,lat,long) )
end


def normal_order(a,b)
  a["comName"] <=> b["comName"]
end
  
results.sort! { |a,b| 
  if a["landmark"].nil?
    if b["landmark"].nil?
      normal_order(a,b)
    else
      1
    end
  elsif b["landmark"].nil?
    -1
  else
    first = a["landmark"] <=> b["landmark"]
    if first == 0
      normal_order(a,b)
    else
      first
    end
  end
}

FCSV.open( plan_file, 'w' ) do |csv_out| 
  csv_out << [ :landmark, :species, :count, :lat, :long, :date, :url, :location, :distance_to_me ]
  results.each do |place|
    lat = place["lat"]
    long = place["lng"]
    distance_to_me = Distance.geo_distance( lat, long, my_location[:lat], my_location[:long] ) / 1.67 # in miles
    url = "http://maps.google.com/?ie=UTF8&t=p&z=13&q=#{lat},#{long}&ll=#{lat},#{long}"
    location = location_map[place["locID"]] || place["locID"] || 'n/a'
    csv_out << ( ["landmark", "comName", "howMany", "lat", "lng", "obsDt"].map {|t| place[t] || 'n/a'} + [ url, location, distance_to_me ] )
  end
end
