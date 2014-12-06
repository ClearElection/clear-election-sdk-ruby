module ClearElection
  module Factory
    def self.seq(key)
      val = (@seq ||= Hash.new(-1))[key] += 1
      "#{key}-#{val}"
    end

    def self.election_uri
      "http://test.example.com/elections/#{seq(:id)}"
    end

    def self.agent_uri(what="agent", host:"agents.example.com")
      "http://#{host}/#{seq(what)}/"
    end

    def self.election(
      signin: nil,
      booth: nil,
      pollsOpen: nil,
      pollsClose: nil
    )
      one_month = 60*60*24*30
      Election.new(
        signin: Election::Agent.new(uri: signin || self.agent_uri("signin")),
        booth: Election::Agent.new(uri: booth || self.agent_uri("booth")),
        pollsOpen: (pollsOpen || Time.now - one_month).to_datetime(),
        pollsClose: (pollsClose || Time.now + one_month).to_datetime(),
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

    def self.ballot(election=nil, ballotId: nil, uniquifier: nil, demographic: nil, invalid: nil)
      election ||= self.election
      Ballot.new(
        ballotId: ballotId || seq(:ballotId),
        uniquifier: uniquifier || seq(:uniquifier),
        contests: election.contests.map { |contest|
          options = contest.candidates.map(&:candidateId)
          options << "ABSTAIN"
          options << "WRITEIN: TestWritein" if contest.writeIn
          options.shuffle!
          options.push "Test-Invalid-CandidateId" if invalid == :candidateId
          Ballot::Contest.new(
            contestId: contest.contestId,
            choices: contest.multiplicity.times.map {|rank|
              Ballot::Choice.new(candidateId: options.pop, rank: rank)
            }
          )
        },
        demographic: demographic
      )
    end
  end
end

