class LevelGen
end

#!/usr/bin/env ruby
require 'terminal_output'
require 'stage'
require 'persistence'

include TerminalOutput

begin
  init(5)
  Persistence::init
  wgetch(@inner_win)
  stage = Stage.new 5, 3..4
  line_map, objects = stage.trivial_solution
  stage.iterate_solutions 0, line_map, objects
  Persistence::get_solution_schemes.each do |p_scheme|
    scheme = stage.unpack_scheme(p_scheme)
    Persistence::get_solutions(p_scheme).each do |p_filling|
      show_position stage, scheme, p_filling.unpack("C*")
    end
  end

#rescue Object => e
#  endwin
#  puts e
ensure
  endwin
end

