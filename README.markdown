
How to use birdwatching planner.

Birdwatching planner is a tool to group together eBird alerts and
figure out where to go birding next time. It assigns each alert to its
geographic zone and produces an easy-to-read CSV with all alerts and
their respective zones. This way you can see, which area is the best
to visit next.

 1. First of all, some preparation:
 
         install ruby (I generally recommend using rbenv and ruby 1.9.3)
         bundle install
    
 1. Then you need a map with regions you are interested in. Google
    maps work great for this. Here's an example of our map for Bay Area:
 
http://maps.google.com/maps/ms?ie=UTF8&hl=en&msa=0&msid=202933467189883314896.00049912d6823abb690f2&ll=37.637072,-122.276459&spn=0.494809,1.126099&t=h&z=10

    You can create your own map and draw your regions on it. The planner will collect all alerts within each region.

 1. When you are done, you will need a KML file for that map. Look for
    KML link above the map on the right. Copy the URL. It should look
    something like this:
 
http://maps.google.com/maps/ms?ie=UTF8&hl=en&t=h&msa=0&output=kml&msid=202933467189883314896.00049912d6823abb690f2

 1. Create a file with your latitude and longitude. By default, we will use file "data/home.yml". 
 
        :lat: 37.553866
        :long: -122.258992
 
 1. Now we can generate our landmarks file from this feed. Run:
 
         bundle exec ruby -I lib lib/google_map_to_landmarks.rb 'Your KML URL in quotes' >data/landmarks.yml
         
    e.g.
    
         bundle exec ruby -I lib lib/google_map_to_landmarks.rb 'http://maps.google.com/maps/ms?authuser=0&vps=2&ie=UTF8&msa=0&output=kml&msid=202933467189883314896.00049a04d9feb0cc487f6' >landmarks.yml
     
 1. Now we need the alerts from eBird. Login to eBird.org and go to
    http://ebird.org/ebird/alerts. Choose your state and click view.
    Save this page as HTML only. In Chrome, choose File/Save as. Then
    choose "Web Page, HTML only". Say, you saved it to
    alerts_05_jan_2011.html. You can also choose "view source" and
    copy all the text into a text editor, then save it.
    
 1. Now we can run the planner:
    
    bundle exec ruby -I lib/ lib/planner.rb data/life_list.csv data/BIRDING_MAP.yaml data/locations-US-CA.json plan.csv

 1. BOOM! We got a CSV file (plan.csv) with all alerts nicely grouped
    by the regions that we outlined on the google map. 
    
    Open it with Excel and have fun!
 
Happy birdwatching!



h2. One more time:

 1. Get the map

    bundle exec ruby -I lib lib/google_map_to_landmarks.rb  >map.yaml

 1. Get the lifelist

    Go to 'http://ebird.org/ebird/MyEBird?cmd=list&rtype=subnational1&r=US-CA&rank=lrec&time=life&fmt=csv'
    Type your password and save it as lifelist.csv

 1. Get the location names
 
   wget -O locations-US-CA.json 'http://ebird.org/ws1.1/ref/hotspot/region?rtype=subnational1&r=US-CA&fmt=json' 

 1. Run the planner

   bundle exec ruby -I lib/ lib/planner.rb data/life_list.csv data/BIRDING_MAP.yaml data/locations-US-CA.json plan.csv

 1. BOOM!
