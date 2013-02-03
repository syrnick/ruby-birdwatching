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

class Planner
  def initialize( lifelist_file, landmarks_file, locations_file, my_location_file )
    @lifelist_file = lifelist_file
    @landmarks_file = landmarks_file
    @locations_file = locations_file
    @my_location_file = my_location_file 
  end

  def find_interesting_observations( max_distance_miles )
    @my_location = File.open( @my_location_file ) {|f| YAML.load(f) }

    landmarks = Birdwatching::Landmarks.from_file( @landmarks_file )

    @location_map = Birdwatching::EBird::Locations.map_from_file( @locations_file )


    # max_distance_miles = 60 # max_distance / 1.609344
    max_distance = max_distance_miles * 1.609344

    puts @my_location
    observations = Birdwatching::EBird::Observations.all_near_location( @my_location, max_distance )

    @my_species = CSV.open( @lifelist_file, :headers => true ).map {|r| r["Species"]}
    new_observations = observations.reject {|o| o["comName"].include?( "/" ) || o["comName"].include?(" sp.") || @my_species.include?(o["comName"]) }

    @new_observations = new_observations.map do |observation|
      lat = observation["lat"]
      long = observation["lng"]
      observation.dup.merge( "landmark" => Birdwatching::Landmarks.closest_landmark_name(landmarks,lat,long) )
    end

    def normal_order(a,b)
      a["comName"] <=> b["comName"]
    end
  
    @new_observations.sort! do |a,b| 
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
    end
  end

  def write_observations( plan_file )
    CSV.open( plan_file, 'w' ) do |csv_out| 
      csv_out << [ :landmark, :species, :count, :lat, :long, :date, :url, :location, :distance_to_me ]
      @new_observations.each do |place|
        lat = place["lat"]
        long = place["lng"]
        distance_to_me = Birdwatching::Geometry::GeoDistance.geo_distance( lat, long, @my_location[:lat], @my_location[:long] ) / 1.67 # in miles
        url = "http://maps.google.com/?ie=UTF8&t=p&z=13&q=#{lat},#{long}&ll=#{lat},#{long}"
        location = @location_map[place["locID"]] || place["locID"] || 'n/a'
        csv_out << ( ["landmark", "comName", "howMany", "lat", "lng", "obsDt"].map {|t| place[t] || 'n/a'} + [ url, location, distance_to_me ] )
      end
    end
  end
end

if __FILE__ == $0
  if ARGV.size == 0
    p "Usage: ruby -I lib/ planner.rb lifelist.csv [landmarks_file=landmarks.yml] [locations_file=locations.json] [plan_file=plan.csv]"
    exit
  end

  lifelist_file = ARGV[0] || "data/lifelist.csv"
  landmarks_file = ARGV[1] || "data/landmarks.yml"
  locations_file = ARGV[2] || "data/locations.json"
  plan_file = ARGV[3] || "plan.csv"
  my_location_file = ARGV[4] || "data/home.yml"

  planner = Planner.new( lifelist_file, landmarks_file, locations_file, my_location_file )
  planner.find_interesting_observations( 60 )
  planner.write_observations( plan_file )
end
