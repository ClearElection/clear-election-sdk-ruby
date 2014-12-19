describe ClearElection::Ballot do

  let(:election) { ClearElection::Factory.election} 

  describe "complete valid ballot" do

    let(:ballot) { ClearElection::Factory.ballot(election) }

    it "is valid" do
      ballot.validate(election)
      expect(ballot).to be_valid
    end
  end

  describe "incomplete ballot" do

    let(:ballot) { ClearElection::Factory.ballot(election, complete: false) }

    it "is not fully valid" do
      ballot.validate(election)
      expect(ballot).not_to be_valid
      expect(ballot.errors.first[:message]).to include 'missing contest'
    end

    it "is valid subject to incompleteness" do
      ballot.validate(election, complete:false)
      expect(ballot).to be_valid
    end

  end

  describe "invalid ballot" do

    def test_invalid_ballot(election, invalid, message)
      ballot = ClearElection::Factory.ballot(election, invalid: invalid)
      ballot.validate(election)
      expect(ballot).not_to be_valid
      expect(ballot.errors.first[:message]).to include message
    end

    it "validates contestId" do
      test_invalid_ballot election, :contestId, "Invalid contest id"
    end

    it "validates candidateId" do
      test_invalid_ballot election, :candidateId, "Invalid candidate id"
    end

    it "validates writeins allowed" do
      election = ClearElection::Factory.election(writeIn: false)
      test_invalid_ballot election, :writeIn, "Write-in not allowed"
    end

    it "validates unique choices" do
      test_invalid_ballot election, :duplicateChoice, "Duplicate choices"
    end

    it "validates ranking" do
      test_invalid_ballot election, :ranking, "Invalid ranking"
    end

    it "validates multiplicity (too few)" do
      test_invalid_ballot election, :multiplicityTooFew, "Invalid multiplicity"
    end

    it "validates multiplicity (too many)" do
      test_invalid_ballot election, :multiplicityTooMany, "Invalid multiplicity"
    end
  end

  describe "json" do

    let(:ballot) { ClearElection::Factory.ballot(election) }

    it "makes round trip" do
      original_json = JSON.generate ballot.as_json
      final_json = JSON.generate ClearElection::Ballot.from_json(JSON.parse original_json).as_json
      expect(final_json).to eq original_json
    end
  end

  describe "order" do
    it "is by ballotId" do
      ballots = 4.times.map { ClearElection::Factory.ballot(election) }
      expect(ballots.shuffle.sort.each_cons(2)).to be_all { |a, b| a.ballotId < b.ballotId }
    end

    it "of contests is by contestId" do
      ballot =  ClearElection::Factory.ballot(election)
      expect(ballot.contests.shuffle.sort.each_cons(2)).to be_all { |a, b| a.contestId < b.contestId }
    end
  end

end
