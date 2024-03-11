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
              { id: 1, name: 'citadel-01', location_id: 1, router_links: [1] },
              { id: 2, name: 'citadel-02', location_id: 1, router_links: [] },
              { id: 3, name: 'core-07', location_id: 7, router_links: [15] },
              { id: 4, name: 'hybrid-x022', location_id: 4, router_links: [14] },
              { id: 5, name: 'meta-04', location_id: 3, router_links: [6, 7] },
              { id: 6, name: 'universal-16', location_id: 3, router_links: [5] },
              { id: 7, name: 'prod', location_id: 3, router_links: [5] },
              { id: 8, name: 'custprod-01', location_id: 6, router_links: [11] },
              { id: 9, name: 'edgesrv-01', location_id: 8, router_links: [14, 15] },
              { id: 10, name: 'proxyA', location_id: 5, router_links: [14] },
              { id: 11, name: 'proxyB', location_id: 2, router_links: [8] },
              { id: 14, name: 'cdn10', location_id: 4, router_links: [4, 9, 10] },
              { id: 15, name: 'cdn20', location_id: 7, router_links: [3, 9] }
            ],
            locations: [
              { id: 1, name: 'Adastral' },
              { id: 2, name: 'London' },
              { id: 3, name: 'Winterbourne House' },
              { id: 4, name: 'Lancaster Brewery' },
              { id: 5, name: 'Lancaster University' },
              { id: 6, name: 'Williamson Park' },
              { id: 7, name: 'Lancaster Castle' },
              { id: 8, name: 'Loughborough University' }
            ]
          }.to_json)
        
        analyzer = RouterLocationAnalyzer.new
        analyzer.analyze_connections
        expect(analyzer.instance_variable_get(:@locations)).to eq({
          'Adastral' => [],
          'London' => ['Williamson Park'],
          'Winterbourne House' => [],
          'Lancaster Brewery' => ['Loughborough University', 'Lancaster University'],
          'Lancaster University' => ['Lancaster Brewery'],
          'Williamson Park' => ['London'],
          'Lancaster Castle' => ['Loughborough University'],
          'Loughborough University' => ['Lancaster Brewery', 'Lancaster Castle']
        })
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
            { id: 1, location_id: 1, router_links: [2] },
            { id: 2, location_id: 2, router_links: [1] }
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
          {'id' => 1, 'location_id' => 1, 'router_links' => [2]},
          {'id' => 2, 'location_id' => 2, 'router_links' => [1]}
        ],
        'locations' => [
          {'id' => 1, 'name' => 'Adastral'},
          {'id' => 2, 'name' => 'London'}
        ]
      })
    end
  end
end
