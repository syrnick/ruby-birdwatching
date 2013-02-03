require 'rubygems'
require 'httparty'
require 'fastercsv'

module Birdwatching
  module EBird
    module Observations
      def self.get( long, lat, max_distance, max_results = 10000 )

        # You can also use post, put, delete, head, options in the same fashion
        response = HTTParty.get("http://ebird.org/ws1.1/data/obs/geo/recent",
                                 :query => { :lat => lat,
                                  :lng => long,
                                  :dist => max_distance,
                                  :back => 7,
                                  :maxResults => max_results,
                                  :locale=>'en_US',
                                  :fmt=>'json'})

        response
      end

      def self.all_near_locations( locations, radius )
        all_observations = locations.map {|loc|
          self.get( loc[:long], loc[:lat], radius )
        }.flatten.uniq
      end
    end
  end
end
