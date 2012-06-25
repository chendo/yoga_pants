require "spec_helper"

module YogaPants
  describe "basic integration tests" do
    subject do
      Client.new("http://localhost:9200/")
    end

    before do
      VCR.use_cassette('before_block') do
        if subject.exists?("/yoga_pants_test")
          subject.delete("/yoga_pants_test")
        end

        if subject.exists?("/yoga_pants_test_1")
          subject.delete("/yoga_pants_test_1")
        end

        subject.post("/yoga_pants_test")
        subject.put("/yoga_pants_test/doc/_mapping", :body => {
          :doc => {
            :properties => {
               :foo => {:type => 'string'}
            }
          }
        })
        subject.post("/yoga_pants_test/_refresh")
      end
    end

    it "indexes a valid document" do
      VCR.use_cassette('indexing') do
        subject.post("/yoga_pants_test/doc/1", :body => {
          :foo => 'bar'
        })
        subject.get("/yoga_pants_test/doc/1").should include({
          '_index' => 'yoga_pants_test',
          '_type' => 'doc',
          '_id' => '1',
          'exists' => true,
          '_source' => {
            'foo' => 'bar'
          }
        })
      end
    end

    describe "bulk operations" do
      it 'does bulk operations just fine' do
        VCR.use_cassette('bulk') do
          subject.bulk("/", [
            [:index, {:_index => 'yoga_pants_test', :_type => 'doc', :_id => 2}, {:foo => 'hello bulk'}],
            [:index, {:_index => 'yoga_pants_test_1', :_type => 'doc2', :_id => 2}, {:foo => 'hello bulk 2'}]
          ], :refresh => true)

          subject.get("/yoga_pants_test/doc/2").should include({
            '_index' => 'yoga_pants_test',
            '_type' => 'doc',
            '_id' => '2',
            'exists' => true,
            '_source' => {
              'foo' => 'hello bulk'
            }
          })

          subject.get("/yoga_pants_test_1/doc2/2").should include({
            '_index' => 'yoga_pants_test_1',
            '_type' => 'doc2',
            '_id' => '2',
            'exists' => true,
            '_source' => {
              'foo' => 'hello bulk 2'
            }
          })
        end
      end
    end

    it "raises an exception on missing documents" do
      VCR.use_cassette('missing') do
        expect { subject.get("/yoga_pants_test/doc/not_exist") }.should raise_error(Client::RequestError, "Error performing HTTP request: 404 Not Found\nBody: #{'{"_index":"yoga_pants_test","_type":"doc","_id":"not_exist","exists":false}'}")
      end
    end

    it "raises an exception on an invalid request" do
      VCR.use_cassette('invalid_request') do
        expect { subject.get("/this_does_not_exist") }.to raise_error(Client::RequestError, "Error performing HTTP request: 400 Bad Request\nBody: No handler found for uri [/this_does_not_exist] and method [GET]")
      end
    end

    it "raises an exception when ES returns a hash with an error object" do
      VCR.use_cassette('error') do
        subject.post("/yoga_pants_test/doc/1", :body => {
          :foo => 'bar'
        })
        expect { subject.get("/yoga_pants_test/doc/1/_mlt?min_term_freq=invalid") }.to raise_error(Client::RequestError, "ElasticSearch Error: Failed to parse int parameter [min_term_freq] with value [invalid]")
      end
    end

  end

  describe "network-related failures" do
    let(:host) { "http://localhost:9200" }
    subject do
      Client.new(host, :connection => {:connect_timeout => 0.01})
    end

    context "connection refused" do
      let(:host) { "http://localhost:1" } # Unlikely to be anything running on this port

      it "raises an RequestError" do
        VCR.use_cassette('connection_refused') do
          expect { subject.exists?("/foo") }.to raise_error(Client::RequestError, "Connection refused to http://localhost:1")
        end
      end
    end

    context "connection timed out" do
      let(:host) { "http://192.168.34.58" } # Ewww but yeah.

      it "raises an RequestError" do
        VCR.use_cassette('timed_out') do
          expect { subject.exists?("/foo") }.to raise_error(Client::RequestError, "Connection timed out to #{host}")
        end
      end
    end
  end

  describe "failing over to other nodes" do
    subject do
      Client.new(hosts)
    end

    describe "connection refused on first node" do
      let(:hosts) { ["http://localhost:1/", "http://localhost:9200/"] }
      it "automatically fails over" do
        subject.exists?("/foo").should == false
      end
    end

    describe "connection timed out on first node" do
      let(:hosts) { ["http://10.13.37.3:1/", "http://localhost:9200/"] }
      it "automatically fails over" do
        subject.exists?("/foo").should == false
      end
    end

  end
end
