require "webmock/rspec"

require_relative "factory"

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
      def stub_election_uri(election: nil, election_uri: nil, booth: nil, signin: nil, pollsOpen: nil, pollsClose: nil, valid: true)
        election_uri ||= ClearElection::Factory.election_uri
        if valid
          election ||= ClearElection::Factory.election(booth: booth, signin: signin, pollsOpen: pollsOpen, pollsClose: pollsClose)
          result = { body: JSON.generate(election.as_json) }
        else
          result = { status: 404 }
        end
        stub_request(:get, election_uri).to_return result
        election_uri
      end

      # creates a webmock stub for signin with an access token
      def stub_election_access_token(election_uri:, election: nil, accessToken: nil, demographic: nil, valid: true)
        accessToken ||= SecureRandom.hex(10)
        if valid
          result = { status: 200, body: JSON.generate(demographic: demographic) }
        else
          result = { status: 403 }
        end
        election ||= ClearElection.read(election_uri)
        stub_request(:post, election.signin.uri + "redeem").with(body: {election: election_uri, accessToken: accessToken}).to_return result
        accessToken
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

      shared_examples "api that verifies election state" do |state|
        describe "verifies election is #{state}" do

          oneDay = 60*60*24

          case state
          when :open
            it "rejects if polls have not opened" do
              Timecop.travel(election.pollsOpen - oneDay) do
                api_bound.call
                expect(response).to have_http_status 403
                expect(JSON.parse(response.body)["error"]).to match /open/i
              end
            end
            it "rejects if polls have closed" do
              Timecop.travel(election.pollsClose + oneDay) do
                api_bound.call
                expect(response).to have_http_status 403
                expect(JSON.parse(response.body)["error"]).to match /open/i
              end
            end

          when :closed
            it "rejects if polls have not closed" do
              Timecop.travel(election.pollsClose - oneDay) do
                api_bound.call
                expect(response).to have_http_status 403
                expect(JSON.parse(response.body)["error"]).to match /closed/i
              end
            end

          else
            raise "Unknown election verification state #{state.inspect}" unless state == :unopen
            it "rejects if polls have opened" do
              Timecop.travel(election.pollsOpen + oneDay) do
                api_bound.call
                expect(response).to have_http_status 403
                expect(JSON.parse(response.body)["error"]).to match /open/i
              end
            end
          end
        end
      end

      shared_examples "api that validates election URI" do |state: nil, agent: nil|

        describe "verifies election URI" do
          it "rejects invalid election URI" do
            apicall.call stub_election_uri(valid: false)
            expect(response).to have_http_status 422
            expect(JSON.parse(response.body)["error"]).to match /uri/i
          end

          it "rejects if I am not #{agent} agent" do
            apicall.call stub_election_uri() # not passing my_agent_uri
            expect(response).to have_http_status 422
            expect(JSON.parse(response.body)["error"]).to match /#{agent} agent/i
          end if agent
        end

        let(:election_uri) { stub_election_uri(agent ? { agent => my_agent_uri } : {}) }

        it_behaves_like "api that verifies election state", state do
          let(:election) { ClearElection.read(election_uri) }
          let(:api_bound) { -> { apicall.call election_uri } }
        end if state

      end
    end
  end
end
