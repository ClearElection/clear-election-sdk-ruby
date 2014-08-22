module ClearElection
  module Rspec

    def self.setup(agent: false)
      RSpec.configure do |config|
        config.include Helpers
        if agent
          config.before(:each) do
            setup_my_agent_uri
          end
        end
      end
    end
      
    module Helpers
      # creates a webmock stub request for an election_uri to return an election
      def stub_election_uri(election: nil, election_uri: nil, booth: nil, signin: nil)
        election_uri ||= ClearElection::Factory.election_uri
        stub_request(:get, election_uri).to_return body: (election || ClearElection::Factory.election(booth: booth, signin: signin)).as_json
        election_uri
      end

      # For use in an agent: create a URI that will act in rspec as if
      # it's URI at which the app was called
      def setup_my_agent_uri
        host! URI(my_agent_uri).host
        allow_any_instance_of(ActionDispatch::Request).to receive(:original_url) { |request|
          request.base_url + URI(my_agent_uri).path + request.original_fullpath
        }
      end

      def my_agent_uri
        @my_agent_uri ||= ClearElection::Factory.agent_uri(Rails.root.basename)
      end
    end
  end
end
