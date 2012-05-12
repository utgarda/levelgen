require "rspec"
require './stage.rb'

describe Stage do
  describe "Initialization" do
    let(:size) {5}
    let(:range) {2..3}
    let(:generatedTypes) {[ [:e,0],
                            [:h,2], [:v,2],
                            [:h,3], [:v,3]].to_set }

    subject { Stage.new(size, range) }

    its(:size){should == size}
    its(:types){should == generatedTypes}

  end
end
