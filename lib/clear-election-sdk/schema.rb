module ClearElection
  module Schema
    extend self

    def _get(group:nil, item:, version:)
      @root ||= Pathname.new(__FILE__).dirname.parent.parent + "schemas"
      JSON.parse(File.read(@root + (group||"") + "#{item}-#{version}.schema.json"))
    end

    def election(version: ELECTION_SCHEMA_VERSION)
      _get(item: "election", version: version)
    end

    def ballot(version: BALLOT_SCHEMA_VERSION)
      _get(item: "election", version: version)
    end

    def api(agent, version:)
      _get(group: "api", item: agent, version:version)
    end
  end
end
