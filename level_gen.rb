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
      options[:size] = size if size > 2 and size%2 == 1
    end
  end.parse!

  Persistence.init options

  #stage = Stage.new options[:size], 2..(options[:size]-1)
  #stage = Stage.new options[:size], (options[:size]-2)..(options[:size]-1)
  stage = Stage.new options[:size], 2..2
  #stage = Stage.new options[:size], 4..4

  RubyProf.start

  #GC::Profiler.enable
  #GC.start

  puts "top_solution_outline = " , (top_solution_outline = stage.iterate_solutions 0)

  puts GC::Profiler.report

  result = RubyProf.stop
  printer = RubyProf::GraphPrinter.new result
  printer.print STDOUT
  #exit


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
 #   scheme = [[[], [], [2, 3], [2], [2]], [[2], [2], [], [], [2]]]


  packed_schemes = Persistence.get_solution_schemes_by_outline top_solution_outline

  puts "initial schemes number : #{packed_schemes.size}"
  # drop vertically symmetrical schemes
  rows_sets = Set.new
  packed_schemes.reject! do |packed|
    rows, columns = stage.unpack_scheme packed
    puts "rows = #{rows}"
    if rows_sets.member? [rows.reverse, columns]
      puts "symmetrical found, rejecting"
      true
    else
      rows_sets << [rows,columns]
      false
    end
  end
  rows_sets = nil

  RubyProf.start
  @@i = 0
  packed_schemes.each do |packed_scheme|
    #scheme = top_solution.branches.keys[top_solution.branches.size / 2]
    pp "Scheme: #{packed_scheme}, number #{@@i+=1} out of #{packed_schemes.size}"
    TerminalOutput.clean_buffer
    bfs = PositionsBFS.new(stage, stage.unpack_scheme(packed_scheme))
    positions = []

    stage.collect_positions top_solution_outline, packed_scheme, stage.trivial_solution.objects do |x|
      pos = bfs.position_from_objects_array(x)
      #puts pos.to_s
      #TerminalOutput.render_objects stage.size, x, " "#, 1
      positions << pos
    end
    #puts "non-intersecting regions : "
    regions = bfs.multi_bfs(positions)
    #regions.each{|x| puts "---------------------------------------------"; pp x}
  end

  result = RubyProf.stop
  printer = RubyProf::GraphPrinter.new result
  printer.print STDOUT

  #puts "schemes total : #{top_solution.branches.size}"
  #end
end

