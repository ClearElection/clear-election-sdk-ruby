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
      pollsClose: nil,
      writeIn: true,
      returns: false
    )
      one_month = 60*60*24*30
      Election.new(
        name: seq("Election Name"),
        signin: Election::Agent.new(uri: signin || self.agent_uri("signin")),
        booth: Election::Agent.new(uri: booth || self.agent_uri("booth")),
        pollsOpen: (pollsOpen || Time.now - one_month).to_datetime(),
        pollsClose: (pollsClose || Time.now + one_month).to_datetime(),
        contests: [
          Factory.contest(ranked: true, multiplicity: 3, writeIn: writeIn, ncandidates: 3),
          Factory.contest(ncandidates: 2)
        ]
      ).tap { |election|
        if returns
          election.set_returns(
            voters: 10.times.map{ { "name" => seq("Voter") } }.sort_by { |v| v[:name] },
            ballots: 10.times.map{ Factory.ballot(election) }.sort
          )
        end
      }
    end

    def self.contest(ranked: nil, multiplicity: nil, writeIn: nil, ncandidates: 3)
      Election::Contest.new(
        contestId: seq(:contestId),
        name: seq("Contest Name"),
        ranked: ranked,
        multiplicity: multiplicity,
        writeIn: writeIn,
        candidates: ncandidates.times.map{ Election::Candidate.new(candidateId: seq(:candidateId), name: seq("Candidate Name")) }
      )
    end

    def self.ballot(election=nil, ballotId: nil, uniquifier: nil, demographic: nil, invalid: nil, complete: true)
      election ||= self.election
      contests = election.contests.dup
      contests = contests.drop(1) if not complete
      contests << Factory.contest if invalid == :contestId
      Ballot.new(
        ballotId: ballotId || seq(:ballotId),
        uniquifier: uniquifier || seq(:uniquifier),
        contests: contests.map { |contest|
          options = contest.candidates.map(&:candidateId)
          options << "ABSTAIN"
          options << "WRITEIN: TestWritein" if contest.writeIn
          options.shuffle!
          options.push "Test-Invalid-CandidateId" if invalid == :candidateId
          options.push "WRITEIN: Test-Unpermitted-Writein" if invalid == :writeIn and not contest.writeIn
          options.push options.last if invalid == :duplicateChoice
          nchoices = contest.multiplicity
          nchoices -= 1 if invalid == :multiplicityTooFew
          nchoices += 1 if invalid == :multiplicityTooMany
          Ballot::Contest.new(
            contestId: contest.contestId,
            choices: nchoices.times.map {|rank|
              rank += 1 if invalid == :ranking
              Ballot::Choice.new(candidateId: options.pop, rank: rank)
            }
          )
        },
        demographic: demographic
      )
    end
  end
end

