module ClearElection

  class Election
    attr_reader :registrar, :booth, :pollsOpen, :pollsClose, :contests, :uri

    def initialize(registrar:, booth:, contests:, pollsOpen:, pollsClose:, uri:nil)
      @registrar = registrar
      @booth = booth
      @contests = contests
      @pollsOpen = pollsOpen
      @pollsClose = pollsClose
      @uri = uri
    end

    def self.from_json(data, uri: nil)
      JSON::Validator.validate!(ClearElection.schema, data, insert_defaults: true)
      self.new(
        registrar: Agent.from_json(data["agents"]["registrar"]),
        booth: Agent.from_json(data["agents"]["booth"]),
        contests: data["contests"].map {|data| Contest.from_json(data) },
        pollsOpen: DateTime.rfc3339(data["schedule"]["pollsOpen"]),
        pollsClose: DateTime.rfc3339(data["schedule"]["pollsClose"]),
        uri: uri
      )
    end

    def as_json()
      data = {
        "version" => "0.0",
        "agents" => {
          "registrar" => @registrar.as_json,
          "booth" => @booth.as_json
        },
        "schedule" => {
          "pollsOpen" => @pollsOpen.rfc3339,
          "pollsClose" => @pollsClose.rfc3339,
        },
        "contests" => @contests.map(&:as_json)
      }
      JSON::Validator.validate!(ClearElection.schema, data)
      data
    end

    # utilities
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
        @uri = URI(uri)
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

      def initialize(contestId:, ranked: nil, multiplicity: nil, writeIn: nil, candidates:)
        @contestId = contestId
        @ranked = ranked || false
        @multiplicity = multiplicity || 1
        @writeIn = writeIn || false
        @candidates = candidates
      end

      def self.from_json(data)
        self.new(
          contestId: data["contestId"],
          ranked: data["ranked"],
          multiplicity: data["multiplicity"],
          writeIn: data["writeIn"],
          candidates: data["candidates"].map {|data| Candidate.from_json(data)}
        )
      end

      def self.as_json
        {
          "contestId" => @contestId,
          "ranked" => @ranked,
          "multiplicity" => @multiplicity,
          "writeIn" => @writeIn,
          "candidates" => @candidates.map(&:as_json)
        }
      end

    end

    class Candidate
      attr_reader :candidateId

      def initialize(candidateId:)
        @candidateId = candidateId
      end

      def self.from_json(data)
        self.new(
          candidateId: data["candidateId"]
        )
      end

      def as_json
        {
          "candidateId" => @candidateId
        }
      end
    end
  end
end