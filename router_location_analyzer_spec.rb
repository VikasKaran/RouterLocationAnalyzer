require_relative 'router_location_analyzer'
require 'rspec'
require 'webmock/rspec'

RSpec.describe RouterLocationAnalyzer do
  describe '#add_connection' do
    it 'adds a connection between two locations' do
      analyzer = RouterLocationAnalyzer.new
      analyzer.send(:add_connection, 'Adastral', 'London')
      expect(analyzer.instance_variable_get(:@locations)).to eq({'Adastral' => ['London'], 'London' => ['Adastral']})
    end
  end

  describe '#analyze_connections' do
    context 'when API response is successful' do
      it 'correctly analyzes connections between locations' do
        stub_request(:get, 'https://my-json-server.typicode.com/marcuzh/router_location_test_api/db').
          to_return(body: {
            routers: [
              { id: 1, location_id: 1, links: [2] },
              { id: 2, location_id: 2, links: [1] }
            ],
            locations: [
              { id: 1, name: 'Adastral' },
              { id: 2, name: 'London' }
            ]
          }.to_json)
        
        analyzer = RouterLocationAnalyzer.new
        analyzer.analyze_connections
        expect(analyzer.instance_variable_get(:@locations)).to eq({'Adastral' => ['London'], 'London' => ['Adastral']})
      end
    end

    context 'when API response times out' do
      it 'raises an error' do
        stub_request(:get, 'https://my-json-server.typicode.com/marcuzh/router_location_test_api/db').
          to_timeout

        analyzer = RouterLocationAnalyzer.new
        expect { analyzer.analyze_connections }.to raise_error(StandardError, 'Request to API timed out')
      end
    end

    context 'when API response is not successful' do
      it 'raises an error' do
        stub_request(:get, 'https://my-json-server.typicode.com/marcuzh/router_location_test_api/db').
          to_return(status: 500)

        analyzer = RouterLocationAnalyzer.new
        expect { analyzer.analyze_connections }.to raise_error(StandardError, 'Failed to fetch data from the API. HTTP status code: 500')
      end
    end
  end

  describe '#fetch_data' do
    it 'correctly fetches data from the API' do
      stub_request(:get, 'https://my-json-server.typicode.com/marcuzh/router_location_test_api/db').
        to_return(body: {
          routers: [
            { id: 1, location_id: 1, links: [2] },
            { id: 2, location_id: 2, links: [1] }
          ],
          locations: [
            { id: 1, name: 'Adastral' },
            { id: 2, name: 'London' }
          ]
        }.to_json)
      
      analyzer = RouterLocationAnalyzer.new
      data = analyzer.send(:fetch_data)
      expect(data).to eq({
        'routers' => [
          {'id' => 1, 'location_id' => 1, 'links' => [2]},
          {'id' => 2, 'location_id' => 2, 'links' => [1]}
        ],
        'locations' => [
          {'id' => 1, 'name' => 'Adastral'},
          {'id' => 2, 'name' => 'London'}
        ]
      })
    end
  end
end
