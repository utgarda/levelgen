require 'redis'

module Persistence
  def self.init(options = nil)
    $redis = options && options[:socket] ?
        Redis.new(:path => options[:socket], :timeout => 100) :
        Redis.new(:timeout => 100)
  end

  def self.add_solution(p_scheme, p_filling)
    $redis.sadd :solutions, p_scheme
    $redis.sadd p_scheme, p_filling
  end

#  def self.store_list(p_scheme)

  def self.get_solution_schemes
    $redis.smembers :solutions
  end

  def self.get_solutions(p_scheme)
    $redis.smembers p_scheme
  end

end