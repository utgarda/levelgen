#require 'persistence'
require 'set'
require './terminal_output.rb'

class Stage
  MAIN_OBJ_LENGTH = 3
  MAX_EMPTY_CELLS = 100

  attr_reader :size
  attr_reader :types
  attr_reader :trivial_solution
  attr_reader :trivial_solution_scheme
  attr_reader :outline_to_solution
  attr_reader :main_object

  class PartialSolution
    attr_reader :i, :count, :branches
    
    def initialize(i, branch_map)
      @i = i
      @branches = branch_map #mapping object placement variants to sub-task results for the remaining outline
      @count = trivial? ? 1 : @branches.values.map(&:count).reduce(:+)
    end

    def trivial?
      @branches.values == [nil]
    end

    def collect_positions(scheme, objects, &block)
      if trivial?
        yield objects
      else
        branches[scheme].each do |type, sub_solution_sub_scheme|
          sub_solution, sub_scheme = sub_solution_sub_scheme
          objects << type << i
          sub_solution.collect_positions(sub_scheme, objects, &block)
          objects.pop 2
        end
      end
    end

  end

  class Position
    attr_reader :empty_cells
    attr_reader :line_map
    attr_reader :objects

    def initialize(stage)
      @stage = stage
      @size = stage.size
      @types = stage.types
      @objects  = []
      @line_map = 0
      @line_map_stack = []
      @empty_cells = 0
    end

    def self.trivial_solution(stage)
      p = Position.new(stage)
      p.push stage.size * (stage.size / 2 + 1) - MAIN_OBJ_LENGTH, stage.main_object
      p
    end

    #def self.trivialSolution(stage)
    #  @@trivialSolutions[[stage.size,stage.main_object]] ||= composeTrivialSolution(stage.size, stage.main_object).freeze
    #end

    def push(i, type)
      if 1 == @line_map[i]
      elsif type == :e0
        @objects << type << i
        @empty_cells += 1
        if block_given?
          yield next_free_position(i+1)
          pop
        end
      #check if the object fits inside the rectangle
      elsif (dir,len = @types[type]; (dir == :h ? i % @size : i / @size) + len > @size)
      elsif ( step = dir == :h ? 1 : @size;
              cell_nums = Array.new(len) { |k| i + k * step };
              cell_nums.any? { |k| @line_map[k] == 1 })
              #check if all required space is free
      else
        @objects << type << i
        @line_map_stack << @line_map
        cell_nums.each{|x| @line_map|=(1<<x)}
        if block_given?
          yield next_free_position(i+1)
          pop
        end
      end
    end

    def next_free_position(i)
      i+=1 while 1 == @line_map[i]
      i
    end

    def pop
      type, i = objects.pop 2
      if type == :e0
        @empty_cells-=1
      else
        @line_map = @line_map_stack.pop
      end
    end
  end

  def initialize(size, object_length_range)
    raise "Even-sized stages not implemented" unless size.odd?
    @size       = size
    @line_map_size = @size**2

    @types = {@empty_cell = :e0 => [:e, 0].freeze,
              @main_object = "h#{MAIN_OBJ_LENGTH}".to_sym => [:h, MAIN_OBJ_LENGTH].freeze
    }
    object_length_range.each do |i|
      @types.merge!({ "h#{i}".to_sym => [:h, i].freeze,
                      "v#{i}".to_sym => [:v, i].freeze })
    end
    @types.freeze

    @trivial_solution = Position.trivial_solution(self).freeze
    @trivial_solution_scheme = objects_map_to_scheme(@trivial_solution.objects).freeze
    
    @trivial_partial = PartialSolution.new(@line_map_size, {@trivial_solution_scheme => nil})
    trivial_outline = @line_map_size
    @outline_to_solution = { trivial_outline   => @trivial_partial}
  end

  def line_map_to_outline(i, line_map)
    ((line_map >> (i)) << 8) + i
  end

  def iterate_solutions(i, position = Position.trivial_solution(self))
    outline_code = line_map_to_outline(i, position.line_map)
     if @outline_to_solution.has_key? outline_code
       @outline_to_solution[outline_code]
     else
       ss_map = {}
       @types.each_key do |t|
         unless  t==:e0 && position.empty_cells >= MAX_EMPTY_CELLS
           position.push(i, t) do |next_i|
             sub_solution = iterate_solutions next_i, position
             sub_solution.branches.each_key do |subScheme|
               s = add_object_to_scheme i, t, subScheme
               ss_map[s]||={}
               ss_map[s][t] = [sub_solution, subScheme]
             end
           end
         end
       end
       @outline_to_solution[outline_code] = ss_map.empty? ? @trivial_partial : PartialSolution.new(i, ss_map)
    end
  end



  def pack_scheme(rows, columns)
    (rows + columns).map { |x| (x || []).join }.join(",").to_sym
  end

  public
  def unpack_scheme(p_scheme)
    scheme = p_scheme.to_s.split(/,/ , -1).map {|s| s.split // }
    #scheme = p_scheme.to_s.split(/,/).map { s.split // } #early optimization is so evil!
    [scheme.slice!(0..@size-1), scheme]
  end
  
  def add_object_to_scheme(i, type, scheme)
    dir, len = @types[type]
    return scheme if dir == :e
    y = i / @size
    x = i % @size    
    rows, columns = unpack_scheme(scheme)
    rows ||= []
    columns ||= []    
    (dir == :h ? (rows[y]||=[]) : (columns[x]||=[])).unshift len
    pack_scheme rows, columns
  end

  def objects_map_to_scheme(objects)
    objects = objects.clone
    rows_scheme     = Array.new(@size) { [] }
    columns_scheme  = Array.new(@size) { [] }
    until objects.empty? do
      type, i = objects.pop 2
      dir, len = @types[type]
      next if dir == :e
      y = i / @size
      x = i % @size
      if dir == :h
        rows_scheme[y] << len
      else
        columns_scheme[x] << len
      end
    end
    pack_scheme rows_scheme, columns_scheme
  end

end
