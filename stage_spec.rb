require "rspec"
require './stage.rb'

describe Stage do
  describe "Initialization" do
    let(:size) {5}
    let(:range) {2..3}
    let(:generated_types) {{ :e0 => [:e,0],
                            :h2 => [:h,2], :v2 => [:v,2],
                            :h3 => [:h,3], :v3 => [:v,3]}
    }
    let(:trivial_line_map){ '00000'\
                            '00000'\
                            '00111'\
                            '00000'\
                            '00000'.reverse.to_i 2
    # main obj starts at 12  ^ ^ ends at 15
    }
    let(:trivial_solution){
      [trivial_line_map, ["h#{Stage::MAIN_OBJ_LENGTH}".to_sym,12] ]
    }
    let(:trivial_solution_scheme){
      scheme = Array.new 10
      scheme[2] = Stage::MAIN_OBJ_LENGTH
      scheme.join(',').to_sym
    }

    subject { Stage.new(size, range) }

    its(:size){ should == size}

    its(:types){ should == generated_types}

    its("trivial_solution.objects"){ should ==  trivial_solution[1]}
    its("trivial_solution.line_map"){ should ==  trivial_line_map}

    its(:trivial_solution_scheme) do
      should == trivial_solution_scheme
    end

    it("should convert line maps to outlines") do
      subject.line_map_to_outline(12,trivial_line_map).class.should == Fixnum
    end

    it('should convert object maps to level schemes') do
      subject.objects_map_to_scheme(trivial_solution[1]).should == trivial_solution_scheme
    end

  end
end
