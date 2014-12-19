module ClearElection

  class Ballot

    SCHEMA_VERSION = 0.0

    attr_reader :ballotId, :uniquifier, :contests, :errors, :demographic

    def self.schema
      ClearElection::Schema.ballot(version: SCHEMA_VERSION)
    end

    def self.from_json(data)
      errors = JSON::Validator.fully_validate(schema, data, insert_defaults: true, errors_as_objects: true)
      return self.new(ballotId: nil, uniquifier: nil, contests: [], errors: errors) unless errors.empty?

      self.new(
        ballotId: data["ballotId"],
        uniquifier: data["uniquifier"],
        contests: data["contests"].map { |data| Contest.from_json(data) },
        demographic: data["demographic"]
      )
    end

    def initialize(ballotId:, uniquifier:, contests:, errors: [], demographic: nil)
      @ballotId = ballotId
      @uniquifier = uniquifier
      @contests = contests
      @demographic = demographic
      @errors = errors
    end

    def validate(election, complete: true)
      @contests.each do |contest|
        @errors += contest.validate(election)
      end
      if complete and not (missing = election.contests.map(&:contestId) - @contests.map(&:contestId)).empty?
        @errors += missing.map { |contestId| { contestId: contestId, message: "missing contest" } }
      end
    end

    def valid?
      @errors.empty?
    end

    def as_json()
      data = {
        "version" => "0.0",
        "ballotId" => @ballotId,
        "uniquifier" => @uniquifier,
        "contests" => @contests.map(&:as_json),
      }
      data["demographic"] = @demographic if @demographic
      JSON::Validator.validate!(Ballot.schema, data)
      data
    end

    def <=>(other)
      [self.ballotId, self.contests] <=> [other.ballotId, other.contests]
    end


    class Contest

      attr_reader :contestId, :choices

      def initialize(contestId:, choices:)
        @contestId = contestId
        @choices = choices
      end

      def validate(election)
        errors = []
        err = { contestId: contestId }
        contest = election.get_contest(contestId)
        if contest.nil?
          errors.push err.merge(message: "Invalid contest id")
        else
          if choices.length != contest.multiplicity
            errors.push err.merge(message: "Invalid multiplicity", multiplicity: choices.length)
          end
          if contest.ranked and choices.map(&:rank).sort != (0...contest.multiplicity).to_a
            errors.push err.merge(message: "Invalid ranking")
          end
          if choices.map(&:candidateId).uniq.length != choices.length
            errors.push err.merge(message: "Duplicate choices")
          end
          choices.each do |choice|
            case
            when choice.writeIn?
              if !contest.writeIn
                errors.push err.merge(message: "Write-in not allowed")
              end
            when choice.candidate?
              if !contest.candidates.map(&:candidateId).include?(choice.candidateId)
                errors.push err.merge(message: "Invalid candidate id", candidateId: choice.candidateId)
              end
            end
          end
        end
        errors
      end

      def <=>(other)
        self.contestId <=> other.contestId
      end

      def self.from_json(data)
        self.new(
          contestId: data["contestId"],
          choices: data["choices"].each_with_index.map{|data, i| Choice.from_json(data, rank: i)}
        )
      end

      def as_json
        {
          "contestId" => @contestId,
          "choices" => @choices.sort_by(&:rank).map(&:as_json)
        }
      end
    end

    class Choice
      attr_reader :candidateId, :rank
      def initialize(candidateId:, rank: nil)
        @candidateId = candidateId
        @rank = rank
      end

      def writeIn?
        @candidateId.start_with?("WRITEIN:")
      end

      def abstain?
        @candidateId == "ABSTAIN"
      end

      def candidate?
        not (writeIn? or abstain?)
      end

      def self.from_json(data, rank: nil)
        self.new(candidateId: data["candidateId"],
                 rank: rank)
      end

      def as_json
        {
          "candidateId" => @candidateId
        }
      end
    end


  end
end
