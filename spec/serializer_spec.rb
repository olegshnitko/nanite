require File.join(File.dirname(__FILE__), 'spec_helper')

describe Nanite::Serializer do

  describe "Format" do

    it "supports JSON format" do
      serializer = Nanite::Serializer.new(:json)
      serializer.instance_eval { @serializers.first }.should == JSON
    end

    it "supports Marshal format" do
      serializer = Nanite::Serializer.new(:marshal)
      serializer.instance_eval { @serializers.first }.should == Marshal
    end

    it "supports YAML format" do
      serializer = Nanite::Serializer.new(:yaml)
      serializer.instance_eval { @serializers.first }.should == YAML
    end

    it "should default to Marshal format if not specified" do
      serializer = Nanite::Serializer.new
      serializer.instance_eval { @serializers.first }.should == Marshal
      serializer = Nanite::Serializer.new(nil)
      serializer.instance_eval { @serializers.first }.should == Marshal
    end

  end # Format

  describe "Serialization of Packet" do

    it "should cascade through available serializers" do
      serializer = Nanite::Serializer.new
      serializer.should_receive(:cascade_serializers).with(:dump, "hello", nil)
      serializer.dump("hello")
    end

    it "should try all three supported formats (JSON, Marshal, YAML)" do
      JSON.should_receive(:dump).with("hello").and_raise(StandardError)
      Marshal.should_receive(:dump).with("hello").and_raise(StandardError)
      YAML.should_receive(:dump).with("hello").and_raise(StandardError)

      lambda { Nanite::Serializer.new.dump("hello") }.should raise_error(Nanite::Serializer::SerializationError)
    end

    it "should raise SerializationError if packet could not be serialized" do
      JSON.should_receive(:dump).with("hello").and_raise(StandardError)
      Marshal.should_receive(:dump).with("hello").and_raise(StandardError)
      YAML.should_receive(:dump).with("hello").and_raise(StandardError)

      serializer = Nanite::Serializer.new
      lambda { serializer.dump("hello") }.should raise_error(Nanite::Serializer::SerializationError)
    end

    it "should return serialized packet" do
      serialized_packet = mock("Packet")
      Marshal.should_receive(:dump).with("hello").and_return(serialized_packet)

      serializer = Nanite::Serializer.new(:marshal)
      serializer.dump("hello").should == serialized_packet
    end
    
    describe "with a specific format" do
      before(:each) do
        @serializer = Nanite::Serializer.new(:secure)
        @packet = "serialized"
      end
      
      it "should override the preferred format and use an insecure one when asked for" do
        serialized = @serializer.dump(@packet, :insecure)
        @serializer.load(serialized, :insecure).should == 'serialized'
      end
      
      it "should use the secure serializer if no special format was given" do
        Nanite::SecureSerializer.should_receive(:dump).and_return "secured"
        @serializer.dump("packet").should == 'secured'
      end
    end

  end

  describe "De-Serialization of Packet" do

    it "should cascade through available serializers" do
      serializer = Nanite::Serializer.new
      serializer.should_receive(:cascade_serializers).with(:load, "olleh", nil)
      serializer.load("olleh")
    end

    it "should try all three supported formats (JSON, Marshal, YAML)" do
      JSON.should_receive(:load).with("olleh").and_raise(StandardError)
      Marshal.should_receive(:load).with("olleh").and_raise(StandardError)
      YAML.should_receive(:load).with("olleh").and_raise(StandardError)

      lambda { Nanite::Serializer.new.load("olleh") }.should raise_error(Nanite::Serializer::SerializationError)
    end

    it "should raise SerializationError if packet could not be de-serialized" do
      JSON.should_receive(:load).with("olleh").and_raise(StandardError)
      Marshal.should_receive(:load).with("olleh").and_raise(StandardError)
      YAML.should_receive(:load).with("olleh").and_raise(StandardError)

      serializer = Nanite::Serializer.new
      lambda { serializer.load("olleh") }.should raise_error(Nanite::Serializer::SerializationError)
    end

    it "should return de-serialized packet" do
      deserialized_packet = mock("Packet")
      Marshal.should_receive(:load).with("olleh").and_return(deserialized_packet)

      serializer = Nanite::Serializer.new(:marshal)
      serializer.load("olleh").should == deserialized_packet
    end

  end # De-Serialization of Packet

end # Nanite::Serializer
