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

  def self.store_sub_solution_for_outline(outline, scheme, type, ss_outline)
    hash_key = (outline << 151) + scheme
    @@redis.multi do
      @@redis.sadd outline, scheme
      @@redis.hset hash_key, type, ss_outline
    end
  end

  def self.store_trivial_if_empty(outline, trivial_scheme)
    @@redis.sadd outline, trivial_scheme unless @@redis.exists outline
  end

  def self.get_type_to_outline_map(outline, packed_scheme)
    Marshal.load @@redis.hget(outline, packed_scheme)
  end

  def self.get_solution_schemes_by_outline(outline)
    @@redis.smembers(outline).map(&:to_i)
  end

end