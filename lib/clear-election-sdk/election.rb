module ClearElection

  class Election

    SCHEMA_VERSION = 0.0

    attr_reader :signin, :booth, :pollsOpen, :pollsClose, :contests, :uri, :voters, :ballots

    def self.schema
      ClearElection::Schema.election(version: SCHEMA_VERSION)
    end

    def initialize(name:, signin:, booth:, contests:, pollsOpen:, pollsClose:, uri:nil, voters:nil, ballots:nil)
      @name = name
      @signin = signin
      @booth = booth
      @contests = contests
      @pollsOpen = pollsOpen
      @pollsClose = pollsClose
      @uri = uri
      @voters = voters || []
      @ballots = ballots || []
    end

    def self.from_json(data, uri: nil)
      ClearElection::Schema.validate!(schema, data, insert_defaults: true)
      self.new(
        name: data["name"],
        signin: Agent.from_json(data["agents"]["signin"]),
        booth: Agent.from_json(data["agents"]["booth"]),
        contests: data["contests"].map {|data| Contest.from_json(data) },
        pollsOpen: DateTime.rfc3339(data["schedule"]["pollsOpen"]),
        pollsClose: DateTime.rfc3339(data["schedule"]["pollsClose"]),
        uri: uri,
        voters: data["returns"]["voters"],
        ballots: data["returns"]["ballots"].map { |data| Ballot.from_json(data) }
      )
    end

    def as_json()
      data = {
        "clearelection" => "v0.0",
        "name" => @name,
        "agents" => {
          "signin" => @signin.as_json,
          "booth" => @booth.as_json
        },
        "schedule" => {
          "pollsOpen" => @pollsOpen.rfc3339,
          "pollsClose" => @pollsClose.rfc3339,
        },
        "contests" => @contests.map(&:as_json)
      }
      data["returns"] = {
        "voters" => @voters,
        "ballots" => @ballots.map(&:as_json)
      }
      ClearElection::Schema.validate!(Election.schema, data)
      data
    end

    def set_returns(voters:, ballots:)
      @voters = voters
      @ballots = ballots
    end

    # utilities
    def polls_have_not_opened?
      DateTime.now < pollsOpen
    end

    def polls_are_now_open?
      DateTime.now.between?(pollsOpen, pollsClose)
    end

    def polls_are_now_closed?
      DateTime.now > pollsClose
    end

    def get_contest(contestId)
      contests.find{|contest| contest.contestId == contestId}
    end


    class Agent
      attr_reader :uri

      def initialize(uri:)
        @uri = Addressable::URI.parse(uri)
      end

      def self.from_json(data)
        self.new(uri: data["uri"].sub(%r{/?$}, '/'))
      end

      def as_json()
        {
          "uri" => @uri.to_s
        }
      end

    end

    class Contest
      attr_reader :contestId, :ranked, :multiplicity, :writeIn, :candidates

      def initialize(contestId:, name:, ranked: nil, multiplicity: nil, writeIn: nil, candidates:)
        @contestId = contestId
        @name = name
        @ranked = ranked || false
        @multiplicity = multiplicity || 1
        @writeIn = writeIn || false
        @candidates = candidates
      end

      def self.from_json(data)
        self.new(
          contestId: data["contestId"],
          name: data["name"],
          ranked: data["ranked"],
          multiplicity: data["multiplicity"],
          writeIn: data["writeIn"],
          candidates: data["candidates"].map {|data| Candidate.from_json(data)}
        )
      end

      def as_json
        {
          "contestId" => @contestId,
          "name" => @name,
          "ranked" => @ranked,
          "multiplicity" => @multiplicity,
          "writeIn" => @writeIn,
          "candidates" => @candidates.map(&:as_json)
        }
      end

    end

    class Candidate
      attr_reader :candidateId

      def initialize(candidateId:, name:)
        @candidateId = candidateId
        @name = name
      end

      def self.from_json(data)
        self.new(
          candidateId: data["candidateId"],
          name: data["name"]
        )
      end

      def as_json
        {
          "candidateId" => @candidateId,
          "name" => @name
        }
      end
    end
  end
end
