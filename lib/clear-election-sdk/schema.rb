module ClearElection
  module Schema
    extend self

    def root
      @root ||= Pathname.new(__FILE__).dirname.parent.parent + "schemas"
    end

    def _get(group:nil, item:, version:, expand: false)
      JSON.parse(File.read(root + (group||"") + "#{item}-#{version}.schema.json")).tap { |json|
        expand_refs!(json) if expand
      }
    end

    def election(version: ELECTION_SCHEMA_VERSION)
      _get(item: "election", version: version)
    end

    def ballot(version: BALLOT_SCHEMA_VERSION)
      _get(item: "ballot", version: version)
    end

    def api(agent, version:)
      _get(group: "api", item: agent, version:version, expand: true)
    end

    def expand_refs!(json)
      json.tap {
        JSON.recurse_proc json do |item|
          if Hash === item and uri = item['$ref']
            uri = URI.parse(uri)
            if uri.scheme
              source = uri
              source = ClearElection::Schema.root.join uri.path.sub(%r{^/}, '') if uri.scheme == 'file'
              item.delete '$ref'
              item.merge! expand_refs! JSON.parse source.read
            end
          end
        end
      }
    end
  end
end
