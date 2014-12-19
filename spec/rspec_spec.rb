ClearElection::Rspec.setup agent: true

#
# Stub out some rails-specific definitions.  These come into play when
# `:agent` is passed as true to ClearElection::Rspec.setup; which then sets
# things up so that rspec-rails will use a particular agent URI as the
# app root.
#
module ::Rails
  def self.root 
    Pathname.new("spec")
  end
end

module ::ActionDispatch
  class Request
    def original_url(request)
    end
  end
end

def host!(hostname)
end

describe ClearElection::Rspec do

  describe "stub_election_uri" do

    it "stubs a valid election uri" do
      election = ClearElection::Factory.election
      uri = stub_election_uri(election: election)
      expect(ClearElection.read(uri).as_json).to eq election.as_json
    end

    it "stubs an invalid election uri" do
      uri = stub_election_uri(valid: false)
      expect(ClearElection.read(uri)).to be_nil
    end

  end

  describe "stub_election_access_token" do

    let(:election)     { ClearElection::Factory.election }
    let(:election_uri) { stub_election_uri(election: election) }
    let(:accessToken) { SecureRandom.hex(10) }
    let(:demographic) { { "group" => "A" } }

    it "stubs a uri that accepts access token and returns demographic" do
      stub_election_access_token(election_uri: election_uri, accessToken: accessToken, demographic: demographic)
      response = Faraday.post(election.signin.uri + "redeem", { election: election_uri, accessToken: accessToken })
      response_json = JSON.parse response.body
      expect(response_json).to eq "demographic" => demographic
    end

    it "stubs a uri that rejects access token" do
      stub_election_access_token(election_uri: election_uri, accessToken: accessToken, demographic: demographic, valid: false)
      response = Faraday.post(election.signin.uri + "redeem", { election: election_uri, accessToken: accessToken })
      expect(response.status).to eq 403
    end

  end

  describe "api election validation" do

    Response = Struct.new(:status, :body) do
      def has_http_status?(status)
        self.status == status
      end
    end

    def response
      @response
    end

    def set_response(status: 200, error: nil)
      body = {}
      body["error"] = error if error
      @response = Response.new(status, JSON.generate(body))
    end

    describe "verifies election agent" do
      it_behaves_like "api that validates election URI", agent: :booth do
        let(:apicall) { -> uri {
          election = ClearElection.read(uri)
          case
          when election.nil? then                 set_response status: 422, error: "invalid uri"
          when election.booth.uri != my_agent_uri then set_response status: 422, error: "not booth agent"
          else                                    set_response
          end
        } }
      end
    end

    describe "verifies election is open" do
      it_behaves_like "api that validates election URI", state: :open do
        let(:apicall) { -> uri {
          election = ClearElection.read(uri)
          case
          when election.nil? then                 set_response status: 422, error: "invalid uri"
          when !election.polls_are_now_open? then set_response status: 403, error: "polls not open"
          else                                    set_response
          end
        } }
      end
    end

    describe "verifies election is closed" do
      it_behaves_like "api that validates election URI", state: :closed do
        let(:apicall) { -> uri {
          election = ClearElection.read(uri)
          case
          when election.nil? then                   set_response status: 422, error: "invalid uri"
          when !election.polls_are_now_closed? then set_response status: 403, error: "polls not closed"
          else                                      set_response
          end
        } }
      end
    end

    describe "verifies election hasn't opened" do
      it_behaves_like "api that validates election URI", state: :unopen do
        let(:apicall) { -> uri {
          election = ClearElection.read(uri)
          case
          when election.nil? then                    set_response status: 422, error: "invalid uri"
          when !election.polls_have_not_opened? then set_response status: 403, error: "polls have opened"
          else                                       set_response
          end
        } }
      end
    end

  end



end
