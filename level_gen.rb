#!/usr/bin/env ruby
# encoding: utf-8
require 'optparse'
require './terminal_output.rb'
require './stage.rb'
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

  stage = Stage.new options[:size], 2..(options[:size]-1)
  #stage = Stage.new options[:size], (options[:size]-2)..(options[:size]-1)
  #stage = Stage.new options[:size], 4..4

  RubyProf.start
  top_solution_outline = stage.iterate_solutions 0
  top_solution = stage.outline_to_solution[top_solution_outline]
  result = RubyProf.stop

  printer = RubyProf::GraphPrinter.new result
  printer.print STDOUT

pause
#rescue Object => e
# endwin
# puts e
#ensure
# endwin
 require 'pp'
 #pp stage.outline_to_solution[25].branches.keys
  scheme = top_solution.branches.keys[5]
  pp "Scheme: #{scheme}"
  top_solution.collect_positions(scheme, stage.trivial_solution.objects){|x| render_objects stage.size, x}
end

