require_relative 'geometry/regions'

module Birdwatching
  module Landmarks
    POI_RADIUS = 1.67

    def self.from_file( landmarks_file )
      return nil unless landmarks_file
      all_landmarks = File.open( landmarks_file ) {|lf| YAML.load(lf)}
      point_landmarks = all_landmarks.select {|lm| lm[:type].nil? || lm[:type]=='point'}
      region_landmarks = all_landmarks.select {|lm| lm[:type]=='path' }
      landmarks = {:point => point_landmarks, :region => region_landmarks}
    end

    def self.closest_landmark_name(all_landmarks,lat,long)
      return nil if all_landmarks.nil?

      f_lat = lat.to_f
      f_long = long.to_f

      landmarks = all_landmarks[:point]
      if landmarks
        all_dist_to_landmark = landmarks.map {|l| [l["name"],Distance.geo_distance(l["lat"],l["long"],f_lat,f_long)]}
        best_landmark = landmarks.map {|l| [l["name"],Distance.geo_distance(l["lat"],l["long"],f_lat,f_long)]}.min {|a,b| a[1] <=> b[1] }
        if best_landmark && best_landmark[1] <= POI_RADIUS
          return best_landmark[0]
        end
      end

      poly_landmarks = all_landmarks[:region]
      best_poly = poly_landmarks.find do |poly|
        Geometry::Regions.is_point_in_poly(f_lat, f_long, poly)
      end
      return best_poly[:name] if best_poly
    end
  end
end
