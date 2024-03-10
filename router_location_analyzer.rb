require 'net/http'
require 'json'

class RouterLocationAnalyzer
  # For actual application, move this to .env as an environment variable.
  API_URL = URI('https://my-json-server.typicode.com/marcuzh/router_location_test_api/db')

  def analyze_connections
    begin
      data = fetch_data
      routers = data['routers']
      locations = data['locations']
      puts routers
      puts locations
      routers.each do |router|
        location_id = router['location_id']
        links = router['router_links']

        location_name = locations.find { |loc| loc['id'] == location_id }['name']
        links.each do |linked_router_id|
          linked_location_id = routers.find { |r| r['id'] == linked_router_id }['location_id']
          linked_location_name = locations.find { |loc| loc['id'] == linked_location_id }['name']
          add_connection(location_name, linked_location_name)
        end
      end
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end

  def print_connections
    @locations.each do |location, connections|
      connections.uniq.each do |connected_location|
        puts "#{location} <-> #{connected_location}" if location != connected_location
      end
    end
  end

  private

  def fetch_data
    response = Net::HTTP.get_response(API_URL)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      raise StandardError, "Failed to fetch data from the API. HTTP status code: #{response.code}"
    end
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    raise StandardError, "Request to API timed out: #{e.message}"
  end

  def initialize
    @locations = {}
  end

  def add_connection(location1, location2)
    @locations[location1] ||= []
    @locations[location1] << location2

    @locations[location2] ||= []
    @locations[location2] << location1
  end
end

# Running the script
analyzer = RouterLocationAnalyzer.new
analyzer.analyze_connections
analyzer.print_connections
