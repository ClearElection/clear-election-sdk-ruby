module ClearElection
  class Ballot
    include ActiveModel::Validations

    attr_reader :contests, :election, :errors

    def self.from_json(data)
      errors = JSON::Validator.fully_validate(ClearElection.schema("ballot"), data, insert_defaults: true, errors_as_objects: true)
      if errors.blank?
        self.new(contests: data["contests"].map { |data| Contest.from_json(data) })
      else
        self.new(contests: [], errors: errors)
      end
    end

    def initialize(contests:, errors: [])
      @contests = contests
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

    def disassociate()
      contests.map { |contest|
        self.class.new(contests: [contest])
      }
    end

    def as_json()
      data = {
        "version" => "0.0",
        "contests" => @contests.map(&:as_json)
      }
      JSON::Validator.validate!(ClearElection.schema("ballot"), data)
      data
    end

    def <=>(other)
      self.contests <=> other.contests
    end

    class Contest

      attr_reader :contestId, :ballotId, :uniquifier, :choices

      def initialize(contestId:, ballotId:, uniquifier:, choices:)
        @contestId = contestId
        @ballotId = ballotId
        @uniquifier = uniquifier
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
        [self.contestId, self.ballotId] <=> [other.contestId, other.ballotId]
      end

      def self.from_json(data)
        self.new(
          ballotId: data["ballotId"],
          contestId: data["contestId"],
          uniquifier: data["uniquifier"],
          choices: data["choices"].each_with_index.map{|data, i| Choice.from_json(data, rank: i)}
        )
      end

      def as_json
        {
          "ballotId" => @ballotId,
          "contestId" => @contestId,
          "uniquifier" => @uniquifier,
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
