require "rspec"
require './stage.rb'

describe Stage do
  describe "Initialization" do
    let(:size) {5}
    let(:range) {2..3}
    let(:generatedTypes) {{ :e0 => [:e,0],
                            :h2 => [:h,2], :v2 => [:v,2],
                            :h3 => [:h,3], :v3 => [:v,3]}
    }
    let(:trivialLineMap){ '00000'\
                          '00000'\
                          '00111'\
                          '00000'\
                          '00000'.reverse.to_i 2
    # main obj starts at 12  ^ ^ ends at 15
    }
    let(:trivialSolution){
      [trivialLineMap, ["h#{Stage::MAIN_OBJ_LENGTH}".to_sym,12] ]
    }
    let(:trivialSolutionScheme){
      scheme = Array.new 10
      scheme[2] = Stage::MAIN_OBJ_LENGTH
      scheme.join(',').to_sym
    }

    subject { Stage.new(size, range) }

    its(:size){ should == size}

    its(:types){ should == generatedTypes}

    its("trivialSolution.objects"){ should ==  trivialSolution[1]}
    its("trivialSolution.lineMap"){ should ==  trivialLineMap}

    its(:trivialSolutionScheme) do
      should == trivialSolutionScheme
    end

    it("should convert line maps to outlines") do
      subject.lineMapToOutline(12,trivialLineMap).class.should == Fixnum
    end

    it('should convert object maps to level schemes') do
      subject.objectsMapToScheme(trivialSolution[1]).should == trivialSolutionScheme
    end

  end
end
