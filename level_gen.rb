#!/usr/bin/env ruby
# encoding: utf-8
require 'optparse'
require './terminal_output.rb'
require './stage_dp.rb'
#require 'persistence'
require './cache.rb'

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

#  init_ncurses(options[:size])
#  Persistence::init(options)

  pause
  

  cache = Cache.new
  #stage = StageDP.new options[:size], 2..(options[:size]-1), cache
  #stage = StageDP.new options[:size], (options[:size]-2)..(options[:size]-1), cache
  stage = StageDP.new options[:size], 4..4, cache

  line_map, objects = stage.composeTrivialSolution
  top_solution = stage.iterate_solutions 0, 0, line_map, objects

#  Persistence::get_solution_schemes.each do |p_scheme|
#    scheme = stage.unpack_scheme(p_scheme)
#    Persistence::get_solutions(p_scheme).each do |p_filling|
#      show_position stage, scheme, p_filling.unpack("C*")
#    end
#  end
pause
rescue Object => e
# endwin
 puts e
ensure
# endwin
 require 'pp'
 #pp stage.outline_to_solution[25].branches.keys
  scheme = top_solution.branches.keys[5]
  pp "Scheme: #{scheme}"
  top_solution.collectPositions(scheme, stage.trivialSolution[1]){|x| renderObjects stage.size, x}
end

