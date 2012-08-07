require 'redis'

module Persistence
  def self.init(options = {})
    @@redis = options[:socket] ?
        Redis.new(:path => options[:socket], :timeout => 100, :namespace => options[:namespace]) :
        Redis.new(:timeout => 100,:namespace => options[:namespace])
  end

  def self.outline_known?(outline)
    @@redis.exists outline
  end

  def self.store_solution_for_outline(outline, solution)
    @@redis.set outline, Marshal.dump(solution)
  end

  def self.get_solution_by_outline(outline)
    Marshal.load @@redis.get(outline)
  end

end