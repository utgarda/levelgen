require 'redis'
require './stage.rb'

module Persistence
  def self.init(options = {})
    @@redis = options[:socket] ?
        Redis.new(:path => options[:socket], :timeout => 100, :namespace => options[:namespace]) :
        Redis.new(:timeout => 100,:namespace => options[:namespace])
  end

  def self.outline_known?(outline)
    @@redis.exists "#{outline}_schemes"
  end

  def self.store_solution_for_outline(outline, solution)
    @@redis.set "#{outline}_schemes", solution.branches.keys.pack("w*")
    @@redis.set "#{outline}_everything_else", Marshal.dump([solution.i, solution.branches.values])
  end

  def self.get_solution_by_outline(outline)
    keys = @@redis.get("#{outline}_schemes").unpack "w*"
    i, values = Marshal.load @@redis.get "#{outline}_everything_else"
    Stage::PartialSolution.new i, Hash[ keys.zip values ]
  end

  def self.get_solution_schemes_by_outline(outline)
    @@redis.get("#{outline}_schemes").unpack "w*"
  end

end