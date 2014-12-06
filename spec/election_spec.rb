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
end
