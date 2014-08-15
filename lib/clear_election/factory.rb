module ClearElection
  module Factory
    def self.election(registrar: "http://dummy-registrar.example.com", booth: "http://dummy-booth.example.com")
      Election.new(
        registrar: Agent.new(uri: registrar),
        booth: Agent.new(uri: booth),
        pollsOpen: DateTime.now - 1.day,
        pollsClose: DateTime.now + 1.day,
        contests: [
          Contest.new(contestId: "Contest0",
                      ranked: true,
                      multiplicity: 3,
                      writeIn: true,
                      candidates: [
                        Candidate.new(candidateId: "Candidate0_A"),
                        Candidate.new(candidateId: "Candidate0_B"),
                        Candidate.new(candidateId: "Candidate0_C"),
                      ]),
          Contest.new(contestId: "Contest1",
                      candidates: [
                        Candidate.new(candidateId: "NO"),
                        Candidate.new(candidateId: "YES"),
                      ]),
        ]
      )
    end
  end
end

