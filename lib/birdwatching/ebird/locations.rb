module Birdwatching
  module EBird
    module Locations
      def self.map_from_file( locations_file )
        location_names = File.open( locations_file ) do |f| JSON.parse(f.read()); end
        location_map = Hash[location_names.map {|l| [l["locID"], l["locName"]] }]
        location_map
      end
    end
  end
end
