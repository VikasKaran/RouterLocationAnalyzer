# frozen_string_literal: true

require 'net/http'
require 'json'

# This class fetches data for router locations and analyses the connections between the locations
class RouterLocationAnalyzer
  API_URL = URI('https://my-json-server.typicode.com/marcuzh/router_location_test_api/db')

  def analyze_connections
    data = fetch_data
    routers = data['routers']
    locations = data['locations']

    routers.each do |router|
      location_name = find_location_name(locations, router['location_id'])
      router['router_links'].each do |linked_router_id|
        linked_location_id = routers.find { |r| r['id'] == linked_router_id }['location_id']
        linked_location_name = find_location_name(locations, linked_location_id)
        add_connection(location_name, linked_location_name)
      end
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
  end

  def print_connections
    @locations.each do |location, connections|
      connections.uniq.each do |connected_location|
        puts "#{location} <-> #{connected_location}"
      end
    end
  end

  private

  def fetch_data
    response = Net::HTTP.get_response(API_URL)

    unless response.is_a?(Net::HTTPSuccess)
      raise StandardError, "Failed to fetch data from the API. HTTP status code: #{response.code}"
    end

    JSON.parse(response.body)
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    raise StandardError, "Request to API timed out: #{e.message}"
  end

  def initialize
    @locations = {}
  end

  def find_location_name(locations, location_id)
    locations.find { |loc| loc['id'] == location_id }['name']
  end

  def add_connection(location1, location2)
    @locations[location1] ||= []
    @locations[location2] ||= []

    return unless location1 != location2

    @locations[location1] << location2 unless @locations[location1].include?(location2)
    @locations[location2] << location1 unless @locations[location2].include?(location1)
  end
end

# Running the script
analyzer = RouterLocationAnalyzer.new
analyzer.analyze_connections
analyzer.print_connections
