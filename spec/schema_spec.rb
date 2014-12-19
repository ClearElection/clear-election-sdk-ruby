describe ClearElection::Schema do

  describe "api" do
    it "returns booth agent schema with ballot schema expanded in it" do
      schema = ClearElection::Schema.api("booth-agent", version: "0.0")
      expect(schema["definitions"]["ballot"]["title"]).to eq "Ballot"
    end
  end
end
