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
      @branches = branch_map.freeze #mapping object placement variants to sub-task results for the remaining outline
      @count = trivial? ? 1 : @branches.values.map(&:count).reduce(:+)
      self.freeze
    end

    def trivial?
      @branches.values == [nil]
    end

    def collect_positions(stage, scheme, objects, &block)
      if trivial?
        yield objects
      else
        branches[scheme].each do |type, outline|
          sub_solution = stage.outline_to_solution[outline]
          sub_scheme = stage.left_remove_object_from_scheme(@i, type, scheme)
          objects << type << @i
          sub_solution.collect_positions(stage, sub_scheme, objects, &block)
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
      return unless check_space(i, type)
      @objects << type << i
      if type == :e0
        @empty_cells += 1
      else
        dir, len = @types[type]
        step = dir == :h ? 1 : @size
        @line_map_stack << @line_map
        len.times{ |k| @line_map |= (1<< (i + k * step)) }
      end
      TerminalOutput.render_objects @size, objects, " "
      if block_given?
        yield next_free_position(i+1)
        pop
      end
    end

    def check_space(i, type)
      return false if type == :e0 && @empty_cells >= MAX_EMPTY_CELLS
      dir, len = @types[type]
      step = dir == :h ? 1 : @size
      len.times do |k|
        return false if @line_map[i + k * step] == 1
      end
      true
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
    @size = size
    @line_map_size = @size**2

    @types = {@empty_cell = :e0 => [:e, 0].freeze,
              @main_object = "h#{MAIN_OBJ_LENGTH}".to_sym => [:h, MAIN_OBJ_LENGTH].freeze
    }
    object_length_range.each do |i|
      @types.merge!({"h#{i}".to_sym => [:h, i].freeze,
                     "v#{i}".to_sym => [:v, i].freeze})
    end
    @types.freeze

    @trivial_solution = Position.trivial_solution(self).freeze
    @trivial_solution_scheme = objects_map_to_scheme(@trivial_solution.objects).freeze
    @trivial_partial = PartialSolution.new(@line_map_size, {@trivial_solution_scheme => nil})
    trivial_outline = @line_map_size
    @outline_to_solution = {trivial_outline => @trivial_partial}

    @allowed_types_for_cell=Array.new(@line_map_size) do |i|
      @types.keys.select { |t|
        dir,len = @types[t]
        (t == :e0 || (object_length_range.include? len)) &&
            (dir == :h ? i % @size : i / @size) + len <= @size && @trivial_solution.check_space(i,t)
      }
    end
    @allowed_types_for_cell.freeze
  end

  def line_map_to_outline(i, line_map)
    ((line_map >> (i)) << 8) + i
  end

  def iterate_solutions(i, position = Position.trivial_solution(self), types_fit = @allowed_types_for_cell)
    outline_code = line_map_to_outline(i, position.line_map)
    unless @outline_to_solution.has_key? outline_code
      ss_map = Hash.new{|h,k| h[k] = {}}
      types_fit[i].each do |t|
        unless  t==:e0 && position.empty_cells >= MAX_EMPTY_CELLS
          position.push(i, t) do |next_i|
            #next_types_fit = (t == :e0 || @types[t][0] == :h) ?
            #    types_fit[(next_i - i)..-1] :
            #    Array.new(@line_map_size-next_i) { |k|
            #      types_fit[k + next_i - i].select { |ft| position.check_space(next_i + k, ft) }
            #    }
            sub_solution_outline = iterate_solutions next_i, position#, next_types_fit
            sub_solution = @outline_to_solution[sub_solution_outline]
            sub_solution.branches.each_key do |subScheme|
              s = add_object_to_scheme i, t, subScheme
              ss_map[s][t] = sub_solution_outline
            end
          end
        end
      end
      @outline_to_solution[outline_code] = ss_map.empty? ? @trivial_partial : PartialSolution.new(i, ss_map)
    end
    outline_code
  end


  def pack_scheme(rows, columns)
    (rows + columns).map! { |x| (x || []).join }.join(",").to_sym
  end

  public
  def unpack_scheme(p_scheme)
    scheme = p_scheme.to_s.split(/,/ , -1).map! {|s| s.split // }
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

  def left_remove_object_from_scheme(i, type, scheme)
    return scheme if type == :e0
    dir = @types[type][0]
    y = i / @size
    x = i % @size
    rows, columns = unpack_scheme(scheme)
    (dir == :h ? rows[y]: columns[x]).shift
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
