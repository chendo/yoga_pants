# YogaPants

A lightweight ElasticSearch ruby gem.

## Features

* Super light-weight, super flexible
* No DSL for queries; only hashes
* Bulk indexing
* Threadsafe
* Handle a list of servers and fallback to other ones
* A solid base to build more complex ES libraries on top of.

## Ruby compatibility

* 1.9.3
* rbx-18mode
* rbx-19mode
* ree

JRuby will probably be supported down the track when I allow other HTTP libraries since it's failing due to httpclient wanting openssl.

## Build status

[![Build Status](https://secure.travis-ci.org/chendo/yoga_pants.png)](http://travis-ci.org/chendo/yoga_pants)

## Installation

Add this line to your application's Gemfile:

    gem 'yoga_pants'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yoga_pants

## Usage

```ruby

client = YogaPants::Client.new("http://localhost:9200")

client.post("staff/person/1", body: {
  name: "John Smith",
  age: 42
})
# => {"ok"=>true, "_index"=>"staff", "_type"=>"person", "_id"=>"1", "_version"=>1}

john = client.get("staff/person/1")
# => {"_index"=>"staff", "_type"=>"person", "_id"=>"1", "_version"=>1, "exists"=>true, "_source"=>
#      {"name"=>"John Smith", "age"=>42}
#    }

# Bulk operations
people = %w(Ben Joe Sue Mary)
operations = []
people.each do |person|
  operations << [
                  :index,            # Operation, can be :index, :create, :delete
                  {_type: 'person'}, # Metadata
                  {
                    name: person     # Document data
                  }
                ]
end
client.bulk("staff/_bulk", operations)
# =>
# {"took"=>1, "items"=>[
#   {"create"=>{"_index"=>"staff", "_type"=>"person", "_id"=>"4Eg1W20qSRKwXEb2oGQjyw", "_version"=>1, "ok"=>true}},
#   {"create"=>{"_index"=>"staff", "_type"=>"person", "_id"=>"ejW8SDPuRzOxqABctV2vpQ", "_version"=>1, "ok"=>true}},
#   {"create"=>{"_index"=>"staff", "_type"=>"person", "_id"=>"NEwb6uFiTYyH0S4j9niRAA", "_version"=>1, "ok"=>true}},
#   {"create"=>{"_index"=>"staff", "_type"=>"person", "_id"=>"TOyfVcYnRH6JvqriO7HV7Q", "_version"=>1, "ok"=>true}}
# ]}

```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
