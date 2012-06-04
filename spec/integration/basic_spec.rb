require "yoga_pants/client"

module YogaPants
  describe "basic integration tests" do
    subject do
      Client.new("http://localhost:9200/")
    end

    before(:all) do
      if subject.exists?("/yoga_pants_test")
        subject.delete("/yoga_pants_test")
      end
      subject.post("/yoga_pants_test")
      subject.put("/yoga_pants_test/doc/_mapping", :body => {
        :doc => {
          :properties => {
             :foo => {:type => 'string'}
          }
        }
      })
    end

    it "indexes a valid document" do
      subject.post("/yoga_pants_test/doc/1", :body => {
        :foo => 'bar'
      })
      subject.get("/yoga_pants_test/doc/1").should == {
        '_index' => 'yoga_pants_test',
        '_type' => 'doc',
        '_id' => '1',
        '_version' => 1,
        'exists' => true,
        '_source' => {
          'foo' => 'bar'
        }
      }
    end

    it "raises an exception on missing documents" do
      expect { subject.get("/yoga_pants_test/doc/not_exist") }.should raise_error(Client::RequestError, "Error performing HTTP request: 404 Not Found")
    end

    it "raises an exception on an invalid request" do
      expect { subject.get("/this_does_not_exist") }.to raise_error(Client::RequestError, "Error performing HTTP request: 400 Bad Request")
    end

    it "raises an exception when ES returns a hash with an error object" do
      subject.post("/yoga_pants_test/doc/1", :body => {
        :foo => 'bar'
      })
      expect { subject.get("/yoga_pants_test/doc/1/_mlt?min_term_freq=invalid") }.to raise_error(Client::RequestError, "Failed to parse int parameter [min_term_freq] with value [invalid]")
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
        expect { subject.exists?("/foo") }.to raise_error(Client::RequestError, "Connection refused to http://localhost:1")
      end
    end

    context "connection timed out" do
      let(:host) { "http://192.168.34.58" } # Ewww but yeah.

      it "raises an RequestError" do
        expect { subject.exists?("/foo") }.to raise_error(Client::RequestError, "Connection timed out to #{host}")
      end
    end

  end
end
