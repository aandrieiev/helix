require File.expand_path('../spec_helper', __FILE__)
require 'helix'

STATS_IMAGE_TYPES = %w(album image)
STATS_MEDIA_TYPES = STATS_IMAGE_TYPES + %w(audio video)
STATS_TYPES       = %w(delivery ingest storage)
MEDIA_NAME_OF     = {
  'album' => 'image',
  'audio' => 'track'
}
INGEST_NAME_OF = {
  'video' => 'publish'
}

describe Helix::Statistics do
  let(:mod) { Helix::Statistics }

  describe "Constants"

  shared_examples_for "clones the stats opts arg" do
    it "should clone the opts arg" do
      opts.should_receive(:clone) { opts }
      mod.send(meth, opts)
    end
  end

  shared_examples_for "standardizes raw stats" do
    it "should return standardize_raw_stats(raw)" do
      mod.should_receive(:standardize_raw_stats).with(:raw_response) { :response }
      expect(mod.send(meth, opts)).to eq(:response)
    end
  end

  STATS_TYPES.each do |stats_type|
    STATS_MEDIA_TYPES.each do |resource_label|

      next if STATS_IMAGE_TYPES.include?(resource_label) and stats_type == 'ingest'

      describe ".#{resource_label}_#{stats_type}" do
        let(:meth)  { "#{resource_label}_#{stats_type}" }
        let(:mock_config) { double(Helix::Config, build_url: :built_url, get_response: :raw_response) }
        before(:each) do
          Helix::Config.stub(:instance) { mock_config }
          mod.stub(:standardize_raw_stats).with(:raw_response) { :response }
        end

        subject     { mod.method(meth) }
        its(:arity) { should eq(-1)    }

        case stats_type
          when 'delivery'
            media_name = MEDIA_NAME_OF[resource_label] || resource_label
            context "when given opts containing a :#{media_name}_id" do
              let(:opts) { {group: :daily, :"#{media_name}_id" => :"the_#{media_name}_id"} }
              it_behaves_like "clones the stats opts arg"
              it "should refer to the Helix::Config instance" do
                Helix::Config.should_receive(:instance) { mock_config }
                mod.send(meth, opts)
              end
              context "when opts contains a :content_type" do
                before(:each) do opts.merge!(content_type: :the_format) end
                it "should call config.build_url(guid: the_#{media_name}_id, resource_label: :#{media_name}s, action: :statistics, content_type: :the_format)" do
                  build_opts_url = {
                    guid:           :"the_#{media_name}_id",
                    resource_label: :"#{media_name}s",
                    action:         :statistics,
                    content_type:   :the_format
                  }
                  mock_config.should_receive(:build_url).with(build_opts_url) { :built_url }
                  mod.send(meth, opts)
                end
              end
              context "when opts did NOT contain a :content_type" do
                it "should call config.build_url(guid: the_#{media_name}_id, resource_label: :#{media_name}s, action: :statistics)" do
                  build_url_opts = {guid: :"the_#{media_name}_id", resource_label: :"#{media_name}s", action: :statistics}
                  mock_config.should_receive(:build_url).with(build_url_opts) { :built_url }
                  mod.send(meth, opts)
                end
              end
              it "should assign config.get_response(built_url, opts.merge(sig_type: :view) => raw" do
                mock_config.should_receive(:get_response).with(:built_url, {group: :daily, sig_type: :view}) { :raw_response }
                mod.send(meth, opts)
              end
              it_behaves_like "standardizes raw stats"
            end
            context "when given opts NOT containing a :#{media_name}_id" do
              let(:opts) { {group: :daily} }
              it_behaves_like "clones the stats opts arg"
              it "should refer to the Helix::Config instance" do
                Helix::Config.should_receive(:instance) { mock_config }
                mod.send(meth, opts)
              end
              context "when opts contains a :content_type" do
                before(:each) do opts.merge!(content_type: :the_format) end
                it "should call config.build_url(resource_label: :statistics, action: :#{media_name}_delivery, content_type: :the_format)" do
                  build_url_opts = {resource_label: :statistics, action: :"#{media_name}_delivery", content_type: :the_format}
                  mock_config.should_receive(:build_url).with(build_url_opts) { :built_url }
                  mod.send(meth, opts)
                end
              end
              context "when opts did NOT contain a :content_type" do
                it "should call config.build_url(resource_label: :statistics, action: :#{media_name}_delivery)" do
                  mock_config.should_receive(:build_url).with({resource_label: :statistics, action: :"#{media_name}_delivery"}) { :built_url }
                  mod.send(meth, opts)
                end
              end
              it "should assign config.get_response(built_url, opts.merge(sig_type: :view) => raw" do
                mock_config.should_receive(:get_response).with(:built_url, {group: :daily, sig_type: :view}) { :raw_response }
                mod.send(meth, opts)
              end
              it_behaves_like "standardizes raw stats"
            end
          when 'ingest'
            media_name   = MEDIA_NAME_OF[resource_label]  || resource_label
            publish_name = INGEST_NAME_OF[resource_label] || 'ingest'
            context "when given opts" do
              context "and opts has no :action key" do
                let(:opts) { {group: :daily} }
                it_behaves_like "clones the stats opts arg"
                it "should refer to the Helix::Config instance" do
                  Helix::Config.should_receive(:instance) { mock_config }
                  mod.send(meth, opts)
                end
                it "should call config.build_url(resource_label: :statistics, action: :#{media_name}_#{publish_name}/brakdown)" do
                  mock_config.should_receive(:build_url).with({resource_label: :statistics, action: :"#{media_name}_#{publish_name}/breakdown"}) { :built_url }
                  mod.send(meth, opts)
                end
                it "should assign config.get_response(built_url, opts.merge(sig_type: :view) => raw" do
                  mock_config.should_receive(:get_response).with(:built_url, {group: :daily, sig_type: :view}) { :raw_response }
                  mod.send(meth, opts)
                end
                it_behaves_like "standardizes raw stats"
              end
              [ :encode, :source, :breakdown ].each do |act|
                context "and opts has an :action value of :#{act}" do
                  let(:opts) { {action: act, group: :daily} }
                  it_behaves_like "clones the stats opts arg"
                  it "should refer to the Helix::Config instance" do
                    Helix::Config.should_receive(:instance) { mock_config }
                    mod.send(meth, opts)
                  end
                  it "should call config.build_url(resource_label: :statistics, action: :#{media_name}_#{publish_name}/#{act})" do
                    mock_config.should_receive(:build_url).with({resource_label: :statistics, action: :"#{media_name}_#{publish_name}/#{act}"}) { :built_url }
                    mod.send(meth, opts)
                  end
                  it "should assign config.get_response(built_url, opts.merge(sig_type: :view) => raw" do
                    mock_config.should_receive(:get_response).with(:built_url, {group: :daily, sig_type: :view}) { :raw_response }
                    mod.send(meth, opts)
                  end
                  it_behaves_like "standardizes raw stats"
                end
              end
            end
          when 'storage'
            media_name   = MEDIA_NAME_OF[resource_label]  || resource_label
            publish_name = INGEST_NAME_OF[resource_label] || 'ingest'
            context "when given opts" do
              let(:opts) { {group: :daily} }
              it_behaves_like "clones the stats opts arg"
              it "should refer to the Helix::Config instance" do
                Helix::Config.should_receive(:instance) { mock_config }
                mod.send(meth, opts)
              end
              it "should call config.build_url(resource_label: :statistics, action: :#{media_name}_#{publish_name}/disk_usage)" do
                mock_config.should_receive(:build_url).with({resource_label: :statistics, action: :"#{media_name}_#{publish_name}/disk_usage"}) { :built_url }
                mod.send(meth, opts)
              end
              it "should assign config.get_response(built_url, opts.merge(sig_type: :view) => raw" do
                mock_config.should_receive(:get_response).with(:built_url, {group: :daily, sig_type: :view}) { :raw_response }
                mod.send(meth, opts)
              end
              it_behaves_like "standardizes raw stats"
            end
          # nested in for case
        end

      end
    end

    describe ".track_#{stats_type}" do
      let(:meth)  { "track_#{stats_type}" }

      subject     { mod.method(meth) }
      its(:arity) { should eq(-1)    }

      context "when given no arg" do
        it "should call audio_#{stats_type}({})" do
          mod.should_receive("audio_#{stats_type}").with({}) { :expected }
          expect(mod.send(meth)).to be(:expected)
        end
      end

      context "when given {}" do
        it "should call audio_#{stats_type}({})" do
          mod.should_receive("audio_#{stats_type}").with({}) { :expected }
          expect(mod.send(meth, {})).to be(:expected)
        end
      end

      context "when given :some_opts" do
        it "should call audio_#{stats_type}(:some_opts)" do
          mod.should_receive("audio_#{stats_type}").with(:some_opts) { :expected }
          expect(mod.send(meth, :some_opts)).to be(:expected)
        end
      end

    end

    next if stats_type == 'ingest'
    describe ".album_#{stats_type}" do
      let(:meth)  { "album_#{stats_type}" }

      subject     { mod.method(meth) }
      its(:arity) { should eq(-1)    }

      context "when given no arg" do
        it "should call image_#{stats_type}({})" do
          mod.should_receive("image_#{stats_type}").with({}) { :expected }
          expect(mod.send(meth)).to be(:expected)
        end
      end

      context "when given {}" do
        it "should call image_#{stats_type}({})" do
          mod.should_receive("image_#{stats_type}").with({}) { :expected }
          expect(mod.send(meth, {})).to be(:expected)
        end
      end

      context "when given :some_opts" do
        it "should call image_#{stats_type}(:some_opts)" do
          mod.should_receive("image_#{stats_type}").with(:some_opts) { :expected }
          expect(mod.send(meth, :some_opts)).to be(:expected)
        end
      end

    end

  end

  describe "#standardize_raw_stats" do
    let(:meth) { :standardize_raw_stats }
    describe "arity" do
      subject { mod.method(meth) }
      its(:arity) { should eq(1) }
    end
    args = [ [], {}, { some_key: :some_value } ]
    args.each do |arg|
      context "when given #{arg.inspect}" do
        it "should eq #{arg.inspect}" do
          expect(mod.send(meth, arg)).to eq(arg)
        end
      end
    end
    context "when given {'statistics_reports' => :expected}" do
      subject { mod.send(meth, {'statistics_reports' => :expected}) }
      it { should eq(:expected) }
    end
  end

end
