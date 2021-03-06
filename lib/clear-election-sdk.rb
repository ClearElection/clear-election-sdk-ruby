require "faraday"
require "json-schema"

require "clear-election-sdk/ballot"
require "clear-election-sdk/election"
require "clear-election-sdk/schema"
require "clear-election-sdk/version"

module ClearElection

  def self.read(uri)
    response = Faraday.get(uri)
    return nil unless response.success?
    Election.from_json(JSON.parse(response.body), uri: uri)
  end

end
