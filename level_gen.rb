#!/usr/bin/env ruby
# encoding: utf-8
require 'optparse'
require './terminal_output.rb'
require './persistence.rb'
require './stage.rb'
require './positions_bfs.rb'
require 'ruby-prof'

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

  Persistence.init options

  #stage = Stage.new options[:size], 2..(options[:size]-1)
  #stage = Stage.new options[:size], (options[:size]-2)..(options[:size]-1)
  stage = Stage.new options[:size], 2..2

  #RubyProf.start

  #GC::Profiler.enable
  #GC.start

  top_solution_outline = stage.iterate_solutions 0
  top_solution = Persistence.get_solution_by_outline(top_solution_outline)

  #puts GC::Profiler.report

  #result = RubyProf.stop
  #printer = RubyProf::GraphPrinter.new result
  #printer.print STDOUT

pause
#rescue Object => e
# endwin
# puts e
#ensure
# endwin
 require 'pp'
 #pp stage.outline_to_solution[25].branches.keys
 # 10.times do |i|
 #   scheme = top_solution.branches.keys[5 + i]
    scheme = [[[], [], [2, 3], [2], [2]], [[2], [2], [], [], [2]]]
    pp "Scheme: #{scheme}"
    TerminalOutput.clean_buffer
  pos = nil
  #bfs = PositionsBFS.new(stage, scheme)
    top_solution.collect_positions(stage, scheme, stage.trivial_solution.objects) do |x|
      #puts (pos = bfs.position_from_objects_array(x)).to_s
      TerminalOutput.render_objects stage.size, x, " ", 1
    end
  #puts "adjacent positions for #{pos} :"
  #bfs.find_adjacent(pos){|p| puts p.to_s }
  #end
end

