require 'redis'
require './stage.rb'

module Persistence
  def self.init(options = {})
    @@redis = options[:socket] ?
        Redis.new(:path => options[:socket], :timeout => 100, :namespace => options[:namespace]) :
        Redis.new(:timeout => 100,:namespace => options[:namespace])
  end

  def self.outline_known?(outline)
    @@redis.exists outline
  end

  def self.store_solution_for_outline(outline, ss_map)
    #TODO get a workaround, connections's lost on hashes sizeed > 600000, or store them one by one
    @@redis.mapped_hmset outline, ss_map.inject({}) { |h, (k, v)| h[k] = Marshal.dump v; h }
  end

  def self.get_type_to_outline_map(outline, packed_scheme)
    Marshal.load @@redis.hget(outline, packed_scheme)
  end

  def self.get_solution_schemes_by_outline(outline)
    @@redis.hkeys(outline).map(&:to_i)
  end

end