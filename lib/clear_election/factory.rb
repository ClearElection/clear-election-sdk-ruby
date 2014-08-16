module ClearElection
  module Factory
    def self.seq(key)
      val = (@seq ||= Hash.new(-1))[key] += 1
      "#{key}-#{val}"
    end

    def self.election(
      registrar: "http://dummy-registrar.example.com",
      booth: "http://dummy-booth.example.com",
      pollsOpen: nil,
      pollsClose: nil
    )
      Election.new(
        registrar: Election::Agent.new(uri: registrar),
        booth: Election::Agent.new(uri: booth),
        pollsOpen: pollsOpen || (DateTime.now - 1.day),
        pollsClose: pollsClose || (DateTime.now + 1.day),
        contests: [
          Election::Contest.new(contestId: seq(:contestId),
                      ranked: true,
                      multiplicity: 3,
                      writeIn: true,
                      candidates: [
                        Election::Candidate.new(candidateId: seq(:candidateId)),
                        Election::Candidate.new(candidateId: seq(:candidateId)),
                        Election::Candidate.new(candidateId: seq(:candidateId)),
                      ]),
          Election::Contest.new(contestId: seq(:contestId),
                      candidates: [
                        Election::Candidate.new(candidateId: seq(:candidateId)),
                        Election::Candidate.new(candidateId: seq(:candidateId)),
                      ]),
        ]
      )
    end

    def self.ballot(election, identify: nil, invalid: nil)
      Ballot.new(
        contests: election.contests.map { |contest|
          if identify
            ballotId, uniquifier = identify.call(contest)
          else
            ballotId = seq(:ballotId)
            uniquifier = seq(:uniquifier)
          end
          options = contest.candidates.map(&:candidateId)
          options << "ABSTAIN"
          options << "WRITEIN: TestWritein" if contest.writeIn
          options.shuffle!
          options.push "Test-Invalid-CandidateId" if invalid == :candidateId
          Ballot::Contest.new(
            contestId: contest.contestId,
            ballotId: ballotId,
            uniquifier: uniquifier,
            choices: contest.multiplicity.times.map {|rank|
              Ballot::Choice.new(candidateId: options.pop, rank: rank)
            }
          )
        }
      )
    end
  end
end

