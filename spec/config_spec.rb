require File.expand_path('../spec_helper', __FILE__)
require 'helix'

describe Helix::Config do

  def set_stubs(obj, even_sig=false)
    obj.instance_variable_set(:@attributes, {})
    obj.stub(:media_type_sym)    { :video      }
    obj.stub(:plural_media_type) { 'videos'    }
    obj.stub(:guid)              { 'some_guid' }
    obj.stub(:signature)         { 'some_sig'  } if even_sig
  end

  let(:klass) { Helix::Config  }
  let(:obj)   { klass.instance }

  subject { klass }

  its(:ancestors) { should include(Singleton) }

  describe "Constants" do
    describe "DEFAULT_FILENAME" do
      subject { klass::DEFAULT_FILENAME }
      it { should eq('./helix.yml') }
    end
    describe "SCOPES" do
      subject { klass::SCOPES }
      it { should eq(%w(reseller company library)) }
    end
    describe "VALID_SIG_TYPES" do
      subject { klass::VALID_SIG_TYPES }
      it { should eq([:ingest, :update, :view]) }
    end
  end

  describe ".load" do
    let(:meth) { :load }
    let(:mock_obj)  { mock(klass)  }
    let(:mock_file) { mock(File)   }
    let(:mock_cred) { :credentials }
    before(:each) do
      klass.stub(:instance) { mock_obj  }
      File.stub(:open)      { mock_file }
      YAML.stub(:load)      { mock_cred }
      mock_obj.stub(:instance_variable_set).with(:@credentials, anything)
    end
    context "when given no arg" do
      before(:each) do mock_obj.stub(:instance_variable_set).with(:@filename, klass::DEFAULT_FILENAME) end
      it "should get the instance" do
        klass.should_receive(:instance) { mock_obj }
        klass.send(meth)
      end
      it "should set @filename to DEFAULT_FILENAME" do
        mock_obj.should_receive(:instance_variable_set).with(:@filename, klass::DEFAULT_FILENAME)
        klass.send(meth)
      end
      it "should File.open(@filename) -> f" do
        File.should_receive(:open).with(klass::DEFAULT_FILENAME) { mock_file }
        klass.send(meth)
      end
      it "should YAML.load(f) -> cred" do
        YAML.should_receive(:load).with(mock_file) { mock_cred }
        klass.send(meth)
      end
      it "should set @credentials to cred" do
        File.stub(:open).with(klass::DEFAULT_FILENAME) { mock_file }
        YAML.stub(:load).with(mock_file) { mock_cred }
        mock_obj.should_receive(:instance_variable_set).with(:@credentials, mock_cred)
        klass.send(meth)
      end
      it "should return the instance" do
        expect(klass.send(meth)).to be(mock_obj)
      end
    end
    context "when given the arg 'some_file.yml'" do
      let(:yaml_arg) { 'some_file.yml' }
      before(:each) do mock_obj.stub(:instance_variable_set).with(:@filename, yaml_arg) end
      it "should get the instance" do
        klass.should_receive(:instance) { mock_obj }
        klass.send(meth, yaml_arg)
      end
      it "should set @filename to DEFAULT_FILENAME" do
        mock_obj.should_receive(:instance_variable_set).with(:@filename, yaml_arg)
        klass.send(meth, yaml_arg)
      end
      it "should File.open(@filename) -> f" do
        File.should_receive(:open).with(yaml_arg) { mock_file }
        klass.send(meth, yaml_arg)
      end
      it "should YAML.load(f) -> cred" do
        YAML.should_receive(:load).with(mock_file) { mock_cred }
        klass.send(meth, yaml_arg)
      end
      it "should set @credentials to cred" do
        File.stub(:open).with(klass::DEFAULT_FILENAME) { mock_file }
        YAML.stub(:load).with(mock_file) { mock_cred }
        mock_obj.should_receive(:instance_variable_set).with(:@credentials, mock_cred)
        klass.send(meth, yaml_arg)
      end
      it "should return the instance" do
        expect(klass.send(meth, yaml_arg)).to be(mock_obj)
      end
    end
  end

  describe "#build_url" do
    site = 'http://example.com'
    let(:meth)  { :build_url }
    subject     { obj.method(meth) }
    its(:arity) { should be(-1) }
    before(:each) do
      obj.credentials = {'site' => site}
    end
    shared_examples_for "reads scope from credentials for build_url" do |media_type,format,more_opts|
      more_opts ||= {}
      guid   = more_opts[:guid]
      action = more_opts[:action]
      before(:each) do obj.credentials = {'site' => 'http://example.com'} end
      context "and credentials has a key for 'reseller'" do
        before(:each) do obj.credentials.merge!('reseller' => 're_id') end
        context "and credentials has a key for 'company'" do
          before(:each) do obj.credentials.merge!('company' => 'co_id') end
          context "and credentials has a key for 'library'" do
            before(:each) do obj.credentials.merge!('library' => 'lib_id') end
            expected_url  = "#{site}/resellers/re_id/companies/co_id/libraries/lib_id/#{media_type}"
            expected_url += "/the_guid"  if guid
            expected_url += "/#{action}" if action
            expected_url += ".#{format}"
            it { should eq(expected_url) }
          end
          context "and credentials does NOT have a key for 'library'" do
            before(:each) do obj.credentials.delete('library') end
            expected_url  = "#{site}/resellers/re_id/companies/co_id/#{media_type}"
            expected_url += "/the_guid"  if guid
            expected_url += "/#{action}" if action
            expected_url += ".#{format}"
            it { should eq(expected_url) }
          end
        end
        context "and credentials does NOT have a key for 'company'" do
          before(:each) do obj.credentials.delete('company') end
          expected_url  = "#{site}/resellers/re_id/#{media_type}"
          expected_url += "/the_guid"  if guid
          expected_url += "/#{action}" if action
          expected_url += ".#{format}"
          it { should eq(expected_url) }
        end
      end
      context "and credentials does NOT have a key for 'reseller'" do
        before(:each) do obj.credentials.delete('reseller') end
        context "and credentials has a key for 'company'" do
          before(:each) do obj.credentials['company'] = 'co_id' end
          context "and credentials has a key for 'library'" do
            before(:each) do obj.credentials['library'] = 'lib_id' end
            expected_url  = "#{site}/companies/co_id/libraries/lib_id/#{media_type}"
            expected_url += "/the_guid"  if guid
            expected_url += "/#{action}" if action
            expected_url += ".#{format}"
            it { should eq(expected_url) }
          end
        end
      end
    end
    context "when given NO opts" do
      subject { obj.send(meth) }
      it_behaves_like "reads scope from credentials for build_url", :videos, :json
    end
    context "when given opts of {}" do
      subject { obj.send(meth, {}) }
      it_behaves_like "reads scope from credentials for build_url", :videos, :json
    end
    context "when given opts of {guid: :the_guid}" do
      subject { obj.send(meth, {guid: :the_guid}) }
      it_behaves_like "reads scope from credentials for build_url", :videos, :json, {guid: :the_guid}
    end
    context "when given opts of {action: :the_action}" do
      subject { obj.send(meth, {action: :the_action}) }
      it_behaves_like "reads scope from credentials for build_url", :videos, :json, {action: :the_action}
    end
    context "when given opts of {guid: :the_guid, action: :the_action}" do
      subject { obj.send(meth, {guid: :the_guid, action: :the_action}) }
      it_behaves_like "reads scope from credentials for build_url", :videos, :json, {guid: :the_guid, action: :the_action}
    end
    [ :videos, :tracks ].each do |media_type|
      context "when given opts[:media_type] of :#{media_type}" do
        subject { obj.send(meth, media_type: media_type) }
        it_behaves_like "reads scope from credentials for build_url", media_type, :json
      end
      context "when given opts[:media_type] of :#{media_type} and opts[:guid] of :the_guid" do
        subject { obj.send(meth, media_type: media_type, guid: :the_guid) }
        it_behaves_like "reads scope from credentials for build_url", media_type, :json, {guid: :the_guid}
      end
      context "when given opts[:media_type] of :#{media_type} and opts[:action] of :the_action" do
        subject { obj.send(meth, media_type: media_type, action: :the_action) }
        it_behaves_like "reads scope from credentials for build_url", media_type, :json, {action: :the_action}
      end
      context "when given opts[:media_type] of :#{media_type}, opts[:guid] of :the_guid, opts[:action] of :the_action" do
        subject { obj.send(meth, media_type: media_type, guid: :the_guid, action: :the_action) }
        it_behaves_like "reads scope from credentials for build_url", media_type, :json, {guid: :the_guid, action: :the_action}
      end
    end
    [ :json, :xml ].each do |format|
      context "when given opts[:format] of :#{format}" do
        subject { obj.send(meth, format: format) }
        it_behaves_like "reads scope from credentials for build_url", :videos, format
      end
      context "when given opts[:format] of :#{format} and opts[:guid] of :the_guid" do
        subject { obj.send(meth, format: format, guid: :the_guid) }
        it_behaves_like "reads scope from credentials for build_url", :videos, format, {guid: :the_guid}
      end
      context "when given opts[:format] of :#{format} and opts[:action] of :the_action" do
        subject { obj.send(meth, format: format, action: :the_action) }
        it_behaves_like "reads scope from credentials for build_url", :videos, format, {action: :the_action}
      end
      context "when given opts[:format] of :#{format}, opts[:guid] of :the_guid, and opts[:action] of :the_action" do
        subject { obj.send(meth, format: format, guid: :the_guid, action: :the_action) }
        it_behaves_like "reads scope from credentials for build_url", :videos, format, {guid: :the_guid, action: :the_action}
      end
      [ :videos, :tracks ].each do |media_type|
        context "when given opts[:format] of :#{format} and opts[:media_type] of :#{media_type}" do
          subject { obj.send(meth, format: format, media_type: media_type) }
          it_behaves_like "reads scope from credentials for build_url", media_type, format
        end
        context "when given opts[:format] of :#{format}, opts[:guid] of :the_guid, and opts[:media_type] of :#{media_type}" do
          subject { obj.send(meth, format: format, guid: :the_guid, media_type: media_type) }
          it_behaves_like "reads scope from credentials for build_url", media_type, format, {guid: :the_guid}
        end
        context "when given opts[:format] of :#{format}, opts[:action] of :the_action, and opts[:media_type] of :#{media_type}" do
          subject { obj.send(meth, format: format, action: :the_action, media_type: media_type) }
          it_behaves_like "reads scope from credentials for build_url", media_type, format, {action: :the_action}
        end
        context "when given opts[:format] of :#{format}, opts[:guid] of :the_guid, opts[:action] of :the_action, and opts[:media_type] of :#{media_type}" do
          subject { obj.send(meth, format: format, guid: :the_guid, action: :the_action, media_type: media_type) }
          it_behaves_like "reads scope from credentials for build_url", media_type, format, {guid: :the_guid, action: :the_action}
        end
      end
    end
  end

  describe "#existing_sig_for" do
    let(:meth)  { :existing_sig_for }

    subject     { obj.method(meth) }
    its(:arity) { should eq(1) }

    context "when given a sig_type" do
      let(:sig_type) { :a_sig_type }
      subject { obj.send(meth, sig_type) }
      context "and sig_expired_for?(sig_type) is true" do
        before(:each) do obj.stub(:sig_expired_for?).with(sig_type) { true } end
        it { should be(nil) }
      end
      context "and sig_expired_for?(sig_type) is false" do
        let(:license_key) { :a_license_key }
        before(:each) do
          obj.stub(:sig_expired_for?).with(sig_type) { false }
          obj.stub(:license_key) { license_key }
        end
        it "should return @signature_for[license_key][sig_type]" do
          mock_sig_for    = {}
          mock_sig_for_lk = {}
          obj.instance_variable_set(:@signature_for, mock_sig_for)
          mock_sig_for.should_receive(:[]).with(license_key) { mock_sig_for_lk }
          mock_sig_for_lk.should_receive(:[]).with(sig_type) { :memoized_sig }
          expect(obj.send(meth, sig_type)).to be(:memoized_sig)
        end
      end
    end
  end

  describe "#get_response" do
    let(:meth)  { :get_response }
    subject     { obj.method(meth) }
    its(:arity) { should eq(-2) }
    context "when given a url and options" do
      let(:string)        { String.new }
      let(:opts)          { {sig_type: :the_sig_type} }
      let(:params)        { { params: { signature: string } } }
      let(:returned_json) { '{"key": "val"}' }
      let(:json_parsed)   { { "key" => "val" } }
      it "should call RestClient.get and return a hash from parsed JSON" do
        obj.stub(:signature).with(:the_sig_type) { string }
        RestClient.should_receive(:get).with(string, params) { returned_json }
        expect(obj.send(meth, string, opts)).to eq(json_parsed)
      end
    end
  end

  describe "#license_key" do
    let(:meth)  { :license_key }
    subject     { obj.method(meth) }
    its(:arity) { should eq(0) }
    it "should return @credentials['license_key']" do
      obj.instance_variable_set(:@credentials, {'license_key' => :lk})
      expect(obj.send(meth)).to be(:lk)
    end
  end

  describe "#prepare_signature_memoization" do
    let(:meth)  { :prepare_signature_memoization }
    subject     { obj.method(meth) }
    its(:arity) { should eq(0) }
    before(:each) do obj.stub(:license_key) { :lk } end
    it "should set @signature_for[license_key] to {}" do
      obj.send(meth)
      expect(obj.instance_variable_get(:@signature_for)).to eq(lk: {})
    end
    it "should set @signature_expiration_for[license_key] to {}" do
      obj.send(meth)
      expect(obj.instance_variable_get(:@signature_expiration_for)).to eq(lk: {})
    end
  end

  describe "#signature" do
    let(:meth)  { :signature }

    subject     { obj.method(meth) }
    its(:arity) { should eq(1) }

    it "should prepare_signature_memoization" do
      obj.should_receive(:prepare_signature_memoization)
      obj.stub(:existing_sig_for) { :some_sig }
      obj.send(meth, :any_sig_type)
    end

    let(:license_key) { :a_license_key }
    before(:each) do
      obj.stub(:license_key) { license_key }
      obj.stub(:prepare_signature_memoization)
    end

    let(:mock_response) { mock(Object) }
    context "when given :some_invalid_sig_type" do
      let(:sig_type) { :some_invalid_sig_type }
      it "should raise an ArgumentError" do
        obj.stub(:existing_sig_for) { nil }
        msg = "I don't understand 'some_invalid_sig_type'. Please give me one of :ingest, :update, or :view."
        expect(lambda { obj.send(meth, sig_type) }).to raise_error(ArgumentError, msg)
      end
    end
    shared_examples_for "gets fresh sig" do |sig_type,url|
      let(:sig_for)     { {license_key => {}} }
      let(:sig_exp_for) { {license_key => {}} }
      before(:each) do
        obj.instance_variable_set(:@signature_for,            sig_for)
        obj.instance_variable_set(:@signature_expiration_for, sig_exp_for)
        RestClient.stub(:get) { :fresh_sig }
      end
      it "should call RestClient.get(#{url})" do
        set_stubs(obj)
        url = "#{obj.credentials['site']}/api/#{sig_type}_key?licenseKey=#{license_key}&duration=1200"
        RestClient.should_receive(:get).with(url) { :fresh_sig }
        expect(obj.send(meth, sig_type)).to be(:fresh_sig)
      end
      it "sets a new sig expiration time" do
        mock_time = mock(Time)
        Time.should_receive(:now) { mock_time }
        mock_time.should_receive(:+).with(klass::TIME_OFFSET) { :new_time }
        obj.send(meth, sig_type)
        expect(obj.instance_variable_get(:@signature_expiration_for)[license_key][sig_type]).to eq(:new_time)
      end
      it "memoizes the freshly-acquired sig" do
        obj.send(meth, sig_type)
        expect(obj.instance_variable_get(:@signature_for)[license_key][sig_type]).to eq(:fresh_sig)
      end
    end
    [ :ingest, :update, :view ].each do |sig_type|
      context "when given :#{sig_type}" do
        url = %q[#{self.credentials['site']}/api/] + sig_type.to_s +
          %q[_key?licenseKey=#{self.license_key}&duration=1200]
        context "and there is an existing_sig_for(sig_type)" do
          before(:each) do obj.stub(:existing_sig_for).with(sig_type) { :memoized_sig } end
          it "should return the existing sig" do
            RestClient.should_not_receive(:get)
            expect(obj.send(meth, sig_type)).to be(:memoized_sig)
          end
        end
        context "and there is NOT an existing_sig_for(sig_type)" do
          before(:each) do obj.stub(:existing_sig_for).with(sig_type) { nil } end
          it_behaves_like "gets fresh sig", sig_type, url
        end
      end
    end
  end

  describe "#sig_expired_for?" do
    let(:meth) { :sig_expired_for? }
    let(:license_key) { :a_license_key }
    before(:each) do obj.stub(:license_key) { :a_license_key } end

    subject     { obj.method(meth) }
    its(:arity) { should be(1) }

    context "when given a sig_type" do
      let(:sig_type) { :a_sig_type }
      let(:mock_expired) { mock(Time) }
      let(:mock_now)     { mock(Time) }
      subject { obj.send(meth, sig_type) }
      context "when @signature_expiration_for[license_key][sig_type] is nil" do
        before(:each) do obj.instance_variable_set(:@signature_expiration_for, {license_key => {sig_type => nil}}) end
        it { should be true }
      end
      context "when @signature_expiration_for[license_key][sig_type] is NOT nil" do
        before(:each) do
          obj.instance_variable_set(:@signature_expiration_for, {license_key => {sig_type => mock_expired}})
          Time.stub(:now) { mock_now }
        end
        context "when @signature_expiration_for[license_key][sig_type] <= Time.now is false" do
          before(:each) do mock_expired.should_receive(:<=).with(mock_now) { false } end
          it { should be false }
        end
        context "when @signature_expiration_for[license_key][sig_type] <= Time.now is true" do
          before(:each) do mock_expired.should_receive(:<=).with(mock_now) { true } end
          it { should be true }
        end
      end
    end
  end
end
