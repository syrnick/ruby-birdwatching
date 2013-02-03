require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'yaml'


## IMPORTANT!!!
## REMOVE xml namespace from that map!


default_map_url='http://maps.google.com/maps/ms?authuser=0&vps=3&hl=en&ie=UTF8&msa=0&output=kml&msid=202933467189883314896.00049a04d9feb0cc487f6'

map_url = ARGV[0] || default_map_url

doc = Nokogiri::XML( open(map_url) )

paths = []
doc.xpath('/kml/Document/Placemark').each do |path|
  p path
  landmark_name = path.xpath("name").first.text
  path = path.xpath(".//coordinates").first.text
  long_lat_path = path.strip.split("\n").map {|l| a = l.strip.split(',').map {|v| v.to_f}; [a[1],a[0]]}
  paths << {:name => landmark_name, :path =>long_lat_path, :type => 'path'}
end

puts YAML.dump(paths)
