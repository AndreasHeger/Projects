require 'net/http'
require 'json'
require 'date'

# Job mappings. Define a name and set the metrics name from graphite
job_mapping = [
   {"name" => "energy",
    "interval" => "5s",
    "since" => "-4hour",
    "metrics" => [ { 'title' => 'Grid',
                     'stat' => 'Wattson.Power.Grid' },
                   { 'title' => 'Solar',
                     'stat' => 'Wattson.Power.Solar' },
                   ]
               },
   {"name" => "solarpower",
    "interval" => "5s",
    "since" => "-24hour",
    "metrics" => [
                  { 'title' => 'East',
                    'stat' => 'Solar.Power.East' },
                  { 'title' => 'West',
                    'stat' => 'Solar.Power.West' },
                  { 'title' => 'Total',
                    'stat' => 'Solar.Power.Total' }
                 ]
               },
   {"name" => "temperature_weekly",
    "interval" => "5s",
    "since" => "-7day",
    "metrics" => [
                  { 'title' => 'Fabian',
                    'stat' => 'Temperature.TopFloor.FrontWall' },
                  { 'title' => 'Niamh',
                    'stat' => 'Temperature.TopFloor.BackWall' },
                  { 'title' => 'Keeva',
                    'stat' => 'Temperature.TopFloor.BackWall' },
                  { 'title' => 'Living room',
                    'stat' => 'Temperature.TopFloor.BackFloor' },
                  { 'title' => 'Livingn room',
                    'stat' => 'Temperature.LivingRoom.Window' },
                  { 'title' => 'Garden room',
                    'stat' => 'Temperature.GroundFloor.BackWindow' },
                  { 'title' => 'Attic',
                    'stat' => 'Temperature.TopFloor.Attic' },
                  { 'title' => 'Boiler',
                    'stat' => 'Temperature.Water.Boiler' },
                  { 'title' => 'Water tank',
                    'stat' => 'Temperature.Water.Tank' },
                  ]
               },
]

job_mapping.each do |entry|

   SCHEDULER.every entry["interval"], :first_in => 0 do |job|

      # create an instance of our Graphite class
      q = Graphite.new(GRAPHITE_HOST, GRAPHITE_PORT)

      series = []
      since = entry["since"]

      entry["metrics"].each do |metric|
        stat = metric['stat']
        _points, current = q.points("#{stat}", since)

        next if points.nil?

        series << { 
          "name"=> metric['title'],
          "data"=> _points }
      end

      send_event(entry["name"], { 
                   series: series })
   end
end

