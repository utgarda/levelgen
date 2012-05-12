#require 'persistence'
require 'set'
require './terminal_output.rb'

class Stage
  MAIN_OBJ_LENGTH = 3
  MAX_EMPTY_CELLS = 100

  attr_reader :size
  attr_reader :types
  #attr_reader :positions
  attr_reader :trivialSolution
  attr_reader :outline_to_solution

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

    def collectPositions(scheme, objects, &block)
      #puts "collectPositions(#{scheme}   ,    #{objects})"
      #puts "i = #{i}"
      #puts " branches[scheme] : ----------------------------"
      #puts branches[scheme]
      #puts
      if trivial?
        #puts "Trivial! ---------------------------------------------"
        yield objects, scheme
      else

        #puts "branches[scheme].values: -----------------------"
        #pp branches[scheme].values
        #puts "-------------------------------"

        #branches[scheme].each do |type,subSolution, subScheme|
      #  puts
      #  puts "type: #{type}"
      #  puts "subSolution.count:"
      #  pp  subSolution.count
      #  puts "subScheme:"
      #  pp subScheme
      #end
      #return
        branches[scheme].each do |type, subSolutionSubScheme|
          subSolution, subScheme = subSolutionSubScheme
          #puts
          #puts "type: #{type}"
          #puts "subSolution:"
          #puts  subSolution
          #puts "subScheme:" + subScheme
          objects << type << i
          subSolution.collectPositions(subScheme, objects, &block)
          objects.pop 2
        end
      end
    end

  end

  def initialize(size, objectLengthRange)
    raise "Even-sized stages not implemented" unless size.odd?
    @size       = size

    @line_map_size = @size**2
    @emptyCell = [:e, 0].freeze
    @mainObject = [:h, MAIN_OBJ_LENGTH].freeze
    @types      = Set.new [@emptyCell, @mainObject]
    objectLengthRange.each { |i| @types += [[:h, i].freeze, [:v, i].freeze] }
    @types.freeze

    @empty_scheme = pack_scheme(a=Array.new(@size){[]}, a)
    @trivialSolution = composeTrivialSolution().freeze
    @trivialSolutionScheme = objectsMapToScheme @trivialSolution[1]
    
    @trivialPartial = PartialSolution.new(@line_map_size, {@trivialSolutionScheme => nil})
    @trivialOutline = @line_map_size
    @outline_to_solution = { @trivialOutline   => @trivialPartial}
  end

  def line_map_to_number(i, lineMap)
    ((lineMap >> (i)) << 8) + i
  end

  def iterate_solutions(i, empty_cells, line_map, objects)

    require 'pp'

    outline_code = line_map_to_number(i, line_map)
    # show_outline outline_code
    # pause
     if @outline_to_solution.has_key? outline_code
       #puts "+"
       @outline_to_solution[outline_code]
     elsif i == @line_map_size # - 1
       puts "Error: cell number #{i} actually reached"
      pause
       exit
     elsif 1 == line_map[i]
       #puts "--"
      #@outline_to_solution[outline_code] =
          iterate_solutions i+1, empty_cells, line_map, objects
     else
       #puts "New outline: i = #{i} , code = #{outline_code}, total outlines: #{@outline_to_solution.keys.size}"
       #puts "i = #{i}" if @outline_to_solution.size % 1000 == 0 #" , total outlines: #{@outline_to_solution.keys.size}"
       ss_map = {}
       @types.each do |t|
         unless  t[0]==:e && empty_cells >= MAX_EMPTY_CELLS
           next_line_map = push i, t, line_map, objects
           if next_line_map
             sub_solution = iterate_solutions i+1, empty_cells + (t[0] == :e ? 1 : 0), next_line_map, objects
             sub_solution.branches.each_key do |sub_scheme|
               s = add_object_to_scheme i, t, sub_scheme
               ss_map[s]||={}
               ss_map[s][t] = [sub_solution, sub_scheme]
             end
           end
           objects.pop 2
         end
       end
       @outline_to_solution[outline_code] = ss_map.empty? ? @trivialPartial : PartialSolution.new(i, ss_map)
    end
  end

  def composeTrivialSolution
    objects  = []
    lineMap = push @size * (@size / 2 + 1) - MAIN_OBJ_LENGTH, @mainObject, 0, objects
    [lineMap, objects]
  end

  private
  def push(i, type, line_map, objects)
    if 1 == line_map[i]
      #puts "push: returning nil,  #{i} taken"
      nil
    elsif (dir, len = type; dir == :e)
      objects << type << i
      line_map
    elsif (y = i / @size; x = i % @size; (dir == :h ? x : y) + len > @size) #check if the object fits inside the rectangle
      #puts "push : returning nil, out of the rectangle"
      nil
    elsif (cell_nums = Array.new(len) { |k| i + k * (dir == :h ? 1 : @size) };
    #puts "cell_nums = #{cell_nums.join(',')}";
    cell_nums.any? { |k| line_map[k] == 1 }) #check if all required space is free
      #puts "push : returning nil, not all cells free"
      nil
      #other constraints to check?
    else
      objects << type << i
      fill_line line_map, cell_nums
    end
  end

  #def push_position(objects)
  #  rows_scheme     = Array.new(@size) { [] }
  #  columns_scheme  = Array.new(@size) { [] }
  #  rows_filling    = Array.new(@size) { [] }
  #  columns_filling = Array.new(@size) { [] }
  #  while objects.size > 0 do
  #    type, i = objects.pop 2
  #    dir, len = type
  #    next if dir == :e
  #    y = i / @size
  #    x = i % @size
  #    if dir == :h
  #      rows_scheme[y] << len
  #      rows_filling[y] << x
  #    else
  #      columns_scheme[x] << len
  #      columns_filling[x] << y
  #    end
  #  end
  #  @cache.store pack_scheme(rows_scheme, columns_scheme),
  #               pack_filling(rows_filling, columns_filling)
  #end

  def pack_scheme(rows, columns)
    (rows + columns).map { |x| (x || []).join }.join(",").to_sym
  end

  def pack_filling(rows, columns)
    (rows + columns).join
  end

  public
  def unpack_scheme(p_scheme)
    scheme = p_scheme.to_s.split(/,/).map { |s| s ? (s.split //): [] }
    [scheme.slice!(0..@size-1), scheme]
  end
  
  def add_object_to_scheme(i, type, scheme)
    dir, len = type
    return scheme if dir == :e
    y = i / @size
    x = i % @size    
    rows, columns = unpack_scheme(scheme)
    rows ||= []
    columns ||= []    
    (dir == :h ? (rows[y]||=[]) : (columns[x]||=[])).unshift len
    pack_scheme rows, columns
  end

  def objectsMapToScheme(objects)
    objects = objects.clone
    rows_scheme     = Array.new(@size) { [] }
    columns_scheme  = Array.new(@size) { [] }
    until objects.empty? do
      type, i = objects.pop 2
      dir, len = type
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

  public
  def fill_line(line_map, cell_nums)
    cell_nums.each{|x| line_map|=(1<<x)}
    line_map
  end
end
