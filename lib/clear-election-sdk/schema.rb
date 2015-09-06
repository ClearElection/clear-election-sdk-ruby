module ClearElection
  module Schema
    extend self

    def root
      @root ||= Pathname.new(__FILE__).dirname.parent.parent + "schemas"
    end

    def election(version: ELECTION_SCHEMA_VERSION)
      _get(item: "election", version: version)
    end

    def ballot(version: BALLOT_SCHEMA_VERSION)
      _get(item: "ballot", version: version)
    end

    def validate!(*args, **kwd)
      validate(*args, **kwd.merge(raise_on_error: true))
    end

    def validate(schema, data, insert_defaults: nil, raise_on_error: false)
      errors = []
      Dir.chdir root do
        args = { insert_defaults: insert_defaults }
        if raise_on_error
          method = :validate!
        else
          method = :fully_validate
          args[:errors_as_objects] = true
        end
        errors = JSON::Validator.send method, schema, data, **args
      end
      errors
    end

    def _get(group:nil, item:, version:, expand: false)
      JSON.parse(File.read(root + (group||"") + "#{item}-#{version}.schema.json")).tap { |json|
        _expand_refs!(json) if expand
      }
    end

    def api(agent, version:)
      _get(group: "api", item: agent, version: version, expand: true)
    end

    def _expand_refs!(json)
      json.tap {
        JSON.recurse_proc json do |item|
          if Hash === item and uri = item['$ref']
            uri = Addressable::URI.parse(uri)
            if uri.scheme
              source = uri
              source = ClearElection::Schema.root.join uri.path.sub(%r{^/}, '') if uri.scheme == 'file'
              item.delete '$ref'
              item.merge! _expand_refs! JSON.parse source.read
            end
          end
        end
      }
    end
  end
end
