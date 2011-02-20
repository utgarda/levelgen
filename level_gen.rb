class LevelGen
end

#!/usr/bin/env ruby
require 'terminal_output'
require 'stage'
include TerminalOutput

begin
  init(5)
  ch = wgetch(@inner_win)
  stage = Stage.new 5, 2..3
  line_map, objects = stage.trivial_solution
  stage.iterate_solutions 0, line_map, objects
  stage.positions.each_pair do |scheme, fillings|
    fillings.each{|f| show_position stage, scheme, Array.new(f)}
  end
#  stage.positions[stage.positions.keys[100]].each_index{|i| show_position stage, stage.positions[i], i%10}


#rescue Object => e
#  endwin
#  puts e
ensure
  endwin
end

