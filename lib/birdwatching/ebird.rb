require 'rubygems'
require 'httparty'
require 'fastercsv'

module EBird
  module Observations
    def self.get( long, lat, max_distance )
      max = 10000
      # You can also use post, put, delete, head, options in the same fashion
      response = HTTParty.get("http://ebird.org/ws1.1/data/obs/geo/recent",
                               :query => { :lat => lat,
                                :lng => long,
                                :dist => max_distance,
                                :back => 7,
                                :maxResults => max,
                                :locale=>'en_US',
                                :fmt=>'json'})

      puts response.body, response.code, response.message, response.headers.inspect
      response
    end

    def self.all_near_locations( locations, radius )
      all_observations = locations.map {|loc|
        self.get( loc[:long], loc[:lat], radius )
      }.flatten.uniq
    end
  end

  module Locations
    def map_from_file( locations_file )
      location_names = File.open( locations_file ) do |f| JSON.parse(f.read()); end
      location_map = Hash[location_names.map {|l| [l["locID"], l["locName"]] }]
      location_map
    end
  end
end
