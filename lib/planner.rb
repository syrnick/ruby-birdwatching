require 'rubygems'
require 'nokogiri'
require 'httparty'
require 'set'
require 'YAML'
require 'csv'
require 'json'

require_relative 'birdwatching/ebird'
require_relative 'birdwatching/landmarks'
require_relative 'birdwatching/geometry/geo_distance'
require_relative 'birdwatching/geometry/regions'


if ARGV.size == 0
  p "Usage: ruby -I lib/ planner.rb lifelist.csv [landmarks_file=landmarks.yml] [locations_file=locations.json] [plan_file=plan.csv]"
  exit
end

lifelist_file = ARGV[0] || "./lifelist.csv"
landmarks_file = ARGV[1] || "landmarks.yml"
locations_file = ARGV[2] || "locations.json"
plan_file = ARGV[3] || "plan.csv"

# Foster City
my_location = { :lat => 37.553866, :long => -122.258992 }

# Las Vegas
my_location = { :lat => 37.0625, :long => -95.677068 }

# Sacramento
my_location = { :lat => 38.57642, :long => -121.497116 }

landmarks = Birdwatching::Landmarks.from_file( landmarks_file )

location_map = Birdwatching::EBird::Locations.map_from_file( locations_file )

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
observations = Birdwatching::EBird::Observations.all_near_locations( locations, radius )

max_distance = 120 
max_distance_miles = max_distance / 1.609344

observations.reject! do |loc|
  Birdwatching::Geometry::GeoDistance.geo_distance(loc["lat"], loc["lng"], my_location[:lat], my_location[:long]) > max_distance
end
p "Got #{observations.size} observations in #{max_distance_miles} miles"


my_species = CSV.open( lifelist_file, :headers => true ).map {|r| r["Species"]}
new_observations = observations.reject {|o| o["comName"].include?( "/" ) || o["comName"].include?(" sp.") || my_species.include?(o["comName"]) }

results = new_observations.map do |observation|
  lat = observation["lat"]
  long = observation["lng"]
  observation.dup.merge( "landmark" => Birdwatching::Landmarks.closest_landmark_name(landmarks,lat,long) )
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

CSV.open( plan_file, 'w' ) do |csv_out| 
  csv_out << [ :landmark, :species, :count, :lat, :long, :date, :url, :location, :distance_to_me ]
  results.each do |place|
    lat = place["lat"]
    long = place["lng"]
    distance_to_me = Birdwatching::Geometry::GeoDistance.geo_distance( lat, long, my_location[:lat], my_location[:long] ) / 1.67 # in miles
    url = "http://maps.google.com/?ie=UTF8&t=p&z=13&q=#{lat},#{long}&ll=#{lat},#{long}"
    location = location_map[place["locID"]] || place["locID"] || 'n/a'
    csv_out << ( ["landmark", "comName", "howMany", "lat", "lng", "obsDt"].map {|t| place[t] || 'n/a'} + [ url, location, distance_to_me ] )
  end
end
