require "faraday"

require "clear_election/election"
require "clear_election/ballot"
require "clear_election/version"

module ClearElection

  def self.schema(item="election", version: "0.0")
    filename = "#{item}.schema-#{version}.json"
    (@schema ||= {})[filename] ||= JSON.parse(File.read(File.dirname(__FILE__) + "/../schema/#{filename}"))
  end

  def self.read(uri)
    response = Faraday.get(uri)
    return nil unless response.success?
    Election.from_json(response.body, uri: uri)
  end

end
