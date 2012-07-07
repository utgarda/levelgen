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
      rows = Array.new(5){[]}
      rows[2] <<  Stage::MAIN_OBJ_LENGTH
      [rows, Array.new(5){[]}]
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

    let(:trivial_0v3){  '10000'\
                        '10000'\
                        '10111'\
                        '00000'\
                        '00000'.reverse.to_i 2
    }

    end

    describe "Position" do
      let(:size) {5}
      let(:range) {2..4}
      let(:trivial_line_map){ '00000'\
                              '00000'\
                              '00111'\
                              '00000'\
                              '00000'.reverse.to_i 2
      }
      let(:trivial_0v3_21h4){ '10000'\
                              '10000'\
                              '10111'\
                              '00000'\
                              '01111'.reverse.to_i 2
      }
      let(:line_map_0v3){ '10000'\
                          '10000'\
                          '10000'\
                          '00000'\
                          '00000'.reverse.to_i 2
      }
      let(:line_map_0h3){ '11100'\
                          '00000'\
                          '00000'\
                          '00000'\
                          '00000'.reverse.to_i 2
      }
      let(:line_map_0h3_8v4){ '11100'\
                              '00010'\
                              '00010'\
                              '00010'\
                              '00010'.reverse.to_i 2
      }

      let(:trivial_solution){
        [trivial_line_map, ["h#{Stage::MAIN_OBJ_LENGTH}".to_sym,12] ]
      }
      let(:trivial_solution_scheme){
        rows = Array.new(5){[]}
        rows[2] <<  Stage::MAIN_OBJ_LENGTH
        [rows, Array.new(5){[]}]
      }

      let(:stage){
        Stage.new(size, range)
      }

      context "acquired via constructor" do
        subject { Stage::Position.new(stage) }

        its(:line_map){ should == 0}

        it "inserts new objects without block provided" do
          subject.push(0, :v3)
          subject.line_map.should == line_map_0v3
        end

        it "inserts objects, provides new context to a block, then reverts its state" do
          subject.push(0, :h3) do |next_free_position|
            next_free_position.should == 3
            subject.line_map.should == line_map_0h3

            subject.push(8, :v4) do |next_after_v4|
              next_after_v4.should == 9
              subject.line_map.should == line_map_0h3_8v4
            end

            subject.line_map.should == line_map_0h3
          end
          subject.line_map.should == 0
        end
      end

      context "acquired via trivial solution factory method" do
        subject {Stage::Position.trivial_solution(stage)}

        its(:line_map){should == trivial_line_map}
        its(:objects){should == trivial_solution[1]}

        it "inserts new objects without block provided" do
          subject.push(0, :v3)
          subject.push(21, :h4)
          subject.line_map.should == trivial_0v3_21h4
        end

      end

    end

end
