require 'httparty'

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

      def self.query_locations( locations, radius )
        all_observations = locations.map {|loc|
          self.get( loc[:long], loc[:lat], radius )
        }.flatten.uniq
      end

      def self.all_near_location( my_location, max_distance )
        use_grid = true
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
        observations = query_locations( locations, radius )

        observations.reject! do |loc|
          Birdwatching::Geometry::GeoDistance.geo_distance(loc["lat"], loc["lng"], my_location[:lat], my_location[:long]) > max_distance
        end
        p "Got #{observations.size} observations in #{max_distance} kilometers (#{(max_distance / 1.609344).to_i} miles)"
        observations
      end
    end
  end
end
