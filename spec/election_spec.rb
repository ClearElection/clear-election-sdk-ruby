describe ClearElection::Election do

  let(:election) { ClearElection::Factory.election }
  let(:pre_open_time) { election.pollsOpen - 1 }
  let(:while_open_time) { election.pollsOpen + (election.pollsClose - election.pollsOpen)/2 }
  let(:post_close_time) { election.pollsClose + 1 }

  describe "polls_are_now_open?" do

    it "returns false before polls open" do
      Timecop.travel pre_open_time do
        expect(election.polls_are_now_open?).to be_falsey
      end
    end

    it "returns true while polls are open" do
      Timecop.travel while_open_time do
        expect(election.polls_are_now_open?).to be_truthy
      end
    end

    it "returns false after polls close" do
      Timecop.travel post_close_time do
        expect(election.polls_are_now_open?).to be_falsey
      end
    end
  end

  describe "polls_are_now_closed?" do

    it "returns false before polls open" do
      Timecop.travel pre_open_time do
        expect(election.polls_are_now_closed?).to be_falsey
      end
    end

    it "returns false while polls are open" do
      Timecop.travel while_open_time do
        expect(election.polls_are_now_closed?).to be_falsey
      end
    end

    it "returns false after polls close" do
      Timecop.travel post_close_time do
        expect(election.polls_are_now_closed?).to be_truthy
      end
    end
  end

  describe "json" do

    it "makes round trip without returns" do
      roundtrip ClearElection::Factory.election(returns: false)
    end

    it "makes round trip with returns" do
      roundtrip ClearElection::Factory.election(returns: true)
    end

    it "works in arbitrary directory" do
      election = ClearElection::Factory.election
      Dir.chdir Dir.mktmpdir do |dir|
        expect{ election.as_json }.to_not raise_error
      end
    end

    private

    def roundtrip(election)
      original_json = JSON.generate election.as_json
      final_json = JSON.generate ClearElection::Election.from_json(JSON.parse original_json).as_json
      expect(final_json).to eq original_json
    end


  end

end
