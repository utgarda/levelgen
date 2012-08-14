require 'set'
require './terminal_output.rb'
require './persistence.rb'

class Stage
  MAIN_OBJ_LENGTH = 3
  EMPTY_CELLS_RANGE = 3..30

  attr_reader :size
  attr_reader :types
  attr_reader :trivial_solution
  attr_reader :trivial_solution_scheme
  attr_reader :outline_to_solution
  attr_reader :main_object

  class Position
    #attr_reader :empty_cells
    attr_reader :line_map
    attr_reader :objects

    def initialize(stage)
      @stage = stage
      @size = stage.size
      @types = stage.types
      @objects  = []
      @line_map = 0
      @line_map_stack = []
      #@empty_cells = 0
    end

    def self.trivial_solution(stage)
      p = Position.new(stage)
      p.push stage.size * (stage.size / 2 + 1) - MAIN_OBJ_LENGTH, stage.main_object
      p
    end

    def push(i, type)
      return unless check_space(i, type)
      @objects << type << i
      unless type == :e0
      #  @empty_cells += 1
      #else
        dir, len = @types[type]
        step = dir == :h ? 1 : @size
        @line_map_stack << @line_map
        len.times{ |k| @line_map |= (1<< (i + k * step)) }
      end
      TerminalOutput.render_objects @size, objects, i
      if block_given?
        yield next_free_position(i+1)
        pop
      end
    end

    def check_space(i, type)
      #return false if type == :e0 && @empty_cells >= MAX_EMPTY_CELLS
      dir, len = @types[type]
      #len = 1 if type == :e0 #TODO maybe it should be :e1 then
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
      #if type == :e0
      #  @empty_cells-=1
      #else
        @line_map = @line_map_stack.pop unless type == :e0
      #end
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
    @packed_trivial_scheme = pack_scheme(@trivial_solution_scheme).freeze
    #@trivial_solutions_map = {pack_scheme(@trivial_solution_scheme) => nil}.freeze
    trivial_outline = @line_map_size
    Persistence.store_trivial_if_empty trivial_outline, @packed_trivial_scheme

    @allowed_types_for_cell=Array.new(@line_map_size) do |i|
      @types.keys.select { |t|
        dir,len = @types[t]
        (t == :e0 || (object_length_range.include? len)) &&
            (dir == :h ? i % @size : i / @size) + len <= @size && @trivial_solution.check_space(i,t)
      }
    end
    @allowed_types_for_cell.freeze
  end

  def collect_positions(outline, packed_scheme, objects, &block)
    #puts "collect_positions( #{outline} , #{packed_scheme} , #{objects} , &block )"
    #puts "unpacked_scheme : #{unpack_scheme packed_scheme}"
    type_to_solution = Persistence.get_type_to_outline_map outline, packed_scheme
    if type_to_solution.nil?
      yield objects
    else
      i = outline & 63
      type_to_solution.each do |type, sub_solution_outline|
        packed_sub_scheme = pack_scheme left_remove_object_from_scheme(i, type, unpack_scheme(packed_scheme))
        objects << type << i
        collect_positions sub_solution_outline, packed_sub_scheme, objects, &block
        objects.pop 2
      end
    end
  end

  def line_map_to_outline(i, line_map)
    ((line_map >> (i)) << 6) + i #TODO adjust shift by grid size, 6 is for <= 7x7
  end

  def iterate_solutions(i, position = Position.trivial_solution(self), types_fit = @allowed_types_for_cell)
    outline_code = line_map_to_outline(i, position.line_map)
    if Persistence.outline_known? outline_code
      print "#{i} "
      return outline_code
    end

    sub_solution_outlines = []
    types_fit[i].each do |t|
        position.push(i, t) do |next_i|
          sub_solution_outlines << [t, iterate_solutions(next_i, position)]
          GC.start
        end
    end

    #ss_map = Hash.new{|h,k| h[k] = {}}
    sub_solution_outlines.each do |type_and_outline|
      GC.start
      t, sub_solution_outline = type_and_outline
      sub_solution_schemes = Persistence.get_solution_schemes_by_outline(sub_solution_outline)
      sub_solution_schemes.each do |packed_sub_scheme|
        scheme = unpack_scheme packed_sub_scheme
        add_object_to_scheme i, t, scheme
        #ss_map[pack_scheme(scheme)][t] = sub_solution_outline
        if check_scheme_constraints(scheme, i)
        Persistence.store_sub_solution_for_outline outline_code, pack_scheme(scheme), t, sub_solution_outline
        end
      end
    end
    Persistence.store_trivial_if_empty outline_code, @packed_trivial_scheme
    outline_code
  end


  def check_scheme_constraints(scheme, i)
    total = 0
    nearly_filled = 0
    scheme.each do |half|
      half.each do |blocks|
        return false if (blocks_sum = blocks.reduce(&:+) || 0) == @size
        total += blocks_sum
        nearly_filled += 1 if blocks_sum == @size - 1
      end
    end
    EMPTY_CELLS_RANGE === (@line_map_size - i - total) && nearly_filled < 4
  end


  def pack_scheme(scheme)
    packed = 0
    scheme.each do |half|
      half.each do |blocks|
        blocks.each{|b| packed = (packed << 3) | b }
        packed = (packed << 2) | blocks.size
      end
    end
    packed
  end

  public
  def unpack_scheme(packed)
    rows, columns = [], []
    [columns, rows].each do |half|
      @size.times do
        blocks = []
        bn = packed & 3
        packed = packed >> 2
        bn.times do
          b = packed & 7
          packed = packed >> 3
          blocks.unshift b
        end
        half.unshift blocks
      end
    end
    [rows,columns]
  end

  def add_object_to_scheme(i, type, scheme)
    dir, len = @types[type]
    #return scheme if dir == :e
    return if dir == :e
    rows, columns = scheme
    if dir == :h
      y = i / @size
      #rows = rows.dup
      #rows[y] = rows[y].clone.unshift len
      rows[y].unshift len
    else
      x = i % @size
      #columns = columns.dup
      #columns[x] = columns[x].clone.unshift len
      columns[x].unshift len
    end
  end

  def left_remove_object_from_scheme(i, type, scheme)
    return scheme if type == :e0
    dir = @types[type][0]
    rows, columns = scheme
    if dir == :h
      y = i / @size
      rows = rows.dup
      rows[y] = rows[y].clone
      rows[y].shift
    else
      x = i % @size
      columns = columns.dup
      columns[x] = columns[x].clone
      columns[x].shift
    end
    [rows, columns]
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
    [rows_scheme, columns_scheme]
  end

end
