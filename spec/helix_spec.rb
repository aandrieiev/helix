require File.expand_path('../spec_helper', __FILE__)
require 'helix'

describe Helix do
  let(:klass) { Helix }

  describe "Constants"

  describe "scope_to_library" do
    let(:meth) { :scope_to_library }
    let(:the_lib_id) { :the_lib_id }
    describe "arity" do
      subject { klass.method(meth) }
      its(:arity) { should eq(1) }
    end
    it "should add the library_id arg to credentials" do
      klass.send(meth, the_lib_id)
      Helix::Config.instance.credentials.should include(library_id: the_lib_id)
    end
  end

end
