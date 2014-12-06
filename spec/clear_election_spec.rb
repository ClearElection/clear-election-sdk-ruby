describe ClearElection do

  it "reads an election" do
    uri = ClearElection::Factory.election_uri
    election = ClearElection::Factory.election

    stub_request(:get, uri).to_return(body: JSON.generate(election.as_json))
    expect(ClearElection.read(uri).as_json).to eq election.as_json
  end

end
