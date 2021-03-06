# ClearElection SDK (ruby)
[![Gem Version](https://badge.fury.io/rb/clear-election-sdk.svg)](http://badge.fury.io/rb/clear-election-sdk)
[![Build Status](https://secure.travis-ci.org/ClearElection/clear-election-sdk-ruby.svg)](http://travis-ci.org/ClearElection/clear-election-sdk-ruby)
[![Coverage Status](https://img.shields.io/coveralls/ClearElection/clear-election-sdk-ruby.svg)](https://coveralls.io/r/ClearElection/clear-election-sdk-ruby)

Ruby SDK to work with ClearElection data.


## Overview

Defines several classes:

* `ClearElection::Election`
* `ClearElection::Ballot`

Defines a top-level function to retrieve an Election from a URI:

	election = ClearElection.read(uri)

Also includes utilities for testing application code that works with elections:

	require 'clear-election-sdk/rspec'
	require 'clear-election-sdk/factory'
	
For now, for more details UTSL.


## Schemas

For now, this repository contains the masters for the schemas.  Currently:

* `schemas/election-0.0.schema.json` 
* `schemas/ballot-0.0.schema.json`
* `schemas/api/booth-agent-0.0.schema.json`


## Installation

Add this line to your application's Gemfile:

    gem 'clear-election-sdk'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install clear_election

## History

* 0.1.2 Bug fix: schema expansion
* 0.1.1 Dependency fix
* 0.1.0 Results, json roundtrip
* 0.0.1 Initial release

## Contributing

1. Fork it ( https://github.com/[my-github-username]/clear_election/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
