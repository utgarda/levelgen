#!/usr/bin/env ruby
require 'optparse'
require 'terminal_output'
require 'stage_dp'
#require 'persistence'
require 'cache'

include TerminalOutput

begin
  options = {:size => 5}
  OptionParser.new do |opts|
    opts.banner = "Usage: level_gen.rb [options]"

    opts.on("-s", "--socket SOCKET", "Specify path to unix socket") do |s|
      options[:socket] = s
    end
    opts.on("--size SIZE", Integer) do |size|
      options[:size] = size if size > 5 and size%2 == 1
    end
  end.parse!

  init_ncurses(options[:size])
#  Persistence::init(options)

  pause
  

  cache = Cache.new
  #stage = StageDP.new options[:size], 2..(options[:size]-1), cache
  #stage = StageDP.new options[:size], (options[:size]-2)..(options[:size]-1), cache
  stage = StageDP.new options[:size], 2..2, cache

  line_map, objects = stage.trivial_solution
  stage.iterate_solutions 0, 0, line_map, objects

#  Persistence::get_solution_schemes.each do |p_scheme|
#    scheme = stage.unpack_scheme(p_scheme)
#    Persistence::get_solutions(p_scheme).each do |p_filling|
#      show_position stage, scheme, p_filling.unpack("C*")
#    end
#  end
pause
rescue Object => e
 endwin
 puts e
ensure
 endwin
 #require 'pp'
 #pp stage.outline_to_solution[stage.outline_to_solution.keys[100]]
end

