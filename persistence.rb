require 'redis'

module Persistence
  def self.init
    $redis = Redis.new
  end

  def self.add_solution(p_scheme, p_filling)
    $redis.sadd :solutions, p_scheme
    $redis.sadd p_scheme, p_filling
  end

  def self.get_solution_schemes
    $redis.smembers :solutions
  end

  def self.get_solutions(p_scheme)
    $redis.smembers p_scheme
  end

end