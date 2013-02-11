require File.expand_path('../spec_helper', __FILE__)
require 'helix'

describe Helix::Album do
  let(:klass) { Helix::Album }

  subject { klass }
  its(:ancestors) { should include(Helix::Base) }
  its(:guid_name) { should eq('album_id') }
  its(:media_type_sym)    { should be(:album)   }
  its(:plural_media_type) { should eq('albums') }
  [:find, :create, :all, :find_all, :where].each do |crud_call|
    it { should respond_to(crud_call) }
  end

  describe ".known_attributes" do
    let(:meth)            { :known_attributes }
    let(:expected_attrs)  { [:title, :description] }
    it "should equal expected_attrs" do
      expect(klass.send(meth)).to eq(expected_attrs)
    end
  end

  describe "Constants"

  describe "an instance" do
    let(:obj) { klass.new({'album_id' => 'some_album_guid'}) }
    subject { obj }
    its(:media_type_sym) { should be(:album) }
    describe "#update" do
      let(:meth) { :update }
      it "should raise an error" do
        expect(lambda { obj.send(meth) }).to raise_error("Albums Update is not currently supported.")
      end
    end
    [:destroy, :update].each do |crud_call|
      it { should respond_to(crud_call) }
    end
  end

end
