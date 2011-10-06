#require 'persistence'
require 'terminal_output'

class StageDP
  MAIN_OBJ_LENGTH = 3
  MAX_EMPTY_CELLS = 1

  attr_reader :size
  attr_reader :types
  attr_reader :positions
  attr_reader :outline_to_solution

  class PartialSolution
    attr_reader :count, :branches
    
    def initialize(i, branch_map = {})
      @i = i
      @branches = branch_map #mapping object placement variants to sub-task results for the remaining outline
      @count = (@branches.values == [nil]) ? 1 : @branches.values.map(&:count).reduce(:+)      
    end
  end

  def initialize(size, object_length_range, cache)
    raise "Even-sized stages not implemented" unless size.odd?
    @size       = size
    empty_scheme = pack_scheme(a=Array.new(@size){[]}, a)
    
    @line_map_size = @size**2
    #@array      = Array.new(@size) { [] }
    #@proper_map = Array.new(2) { Array.new(@size) { [] } }
    @types      = [[:e, 0].freeze]
    object_length_range.each { |i| @types += [[:h, i].freeze, [:v, i].freeze] }
    @types.freeze
    @cache      = cache
    trivial_outline = 0
    #(@line_map_size - 1).times{trivial_outline+=1; trivial_outline = trivial_outline << 1}
    #trivial_outline +=1
    #puts trivial_outline
#    @outline_to_solution = { @line_map_size - 1   => PartialSolution.new}
    @outline_to_solution = { @line_map_size   => PartialSolution.new(@line_map_size, {empty_scheme => nil})}
    # puts "end_outline = #{(@line_map_size-1).to_s(2)}"
    @shortest_outline = @line_map_size
#    Struct.new("State", :i, :line_map, :objects, :empty_cells)
  end

  def line_map_to_number(i, line_map)
    #(line_map[i+1..-1].inject(0){|binary, cell| (cell ? 1 : 0) + (binary << 1)} << 8) + i
    ((line_map >> (i)) << 8) + i
  end

  def iterate_solutions(i, empty_cells, line_map, objects)
    outline_code = line_map_to_number(i, line_map)
    show_outline outline_code
    # pause
    #puts "\niteration: i = #{i}\nline_map =     #{line_map.to_s(2)}\noutline_code = #{outline_code.to_s(2)}"
     if @outline_to_solution.has_key? outline_code
       #puts "+"
       @outline_to_solution[outline_code]
     elsif i == @line_map_size # - 1
       puts "Error: cell number #{i} actually reached"
      pause
       exit
     # #return if empty_cells > MAX_EMPTY_CELLS
     # #@outline_to_solution[i, line_map]
     # puts "Error: cell number #{i} actually reached"
     # #push_position objects.clone
     # exit
     elsif 1 == line_map[i]
       #puts "--"
      #@outline_to_solution[outline_code] =
          iterate_solutions i+1, empty_cells, line_map, objects
     else
       #puts "New outline: i = #{i} , code = #{outline_code}, total outlines: #{@outline_to_solution.keys.size}"
       #puts "i = #{i}" if @outline_to_solution.size % 1000 == 0 #" , total outlines: #{@outline_to_solution.keys.size}"
       ss_map = {}
       @types.each { |t|
        if ( (t[0]!=:e) || (empty_cells<MAX_EMPTY_CELLS)) && (next_line_map = push i, t, line_map, objects)
          sub_solution = iterate_solutions i+1, empty_cells + (t[0] == :e ? 1 : 0), next_line_map, objects
          sub_solution.branches.each_key do |sub_scheme|
            s = add_object_to_scheme i, t, sub_scheme

#            endwin
#            puts "YES"
#            require 'pp'
#            pp ss_map
#            pp s
#            exit
            
            ss_map[s]||={}
            ss_map[s][t] = [sub_solution, sub_scheme]
          end                                
          objects.pop 2
        end
      }
       @outline_to_solution[outline_code] = PartialSolution.new(i, ss_map)
       # (@shortest_outline = i; puts "shortest = #{@shortest_outline}") if i < @shortest_outline
    end
  end

  def trivial_solution
    line_map = 0 #Array.new(@size**2, false)
    objects  = []
    line_map = push_main line_map, objects
    [line_map, objects]
  end

  private
  def push_main(line_map, objects)
    # puts "--------push_main"
    main_obj_type = [:h, MAIN_OBJ_LENGTH]
    push @size * (@size / 2 + 1) - MAIN_OBJ_LENGTH, main_obj_type, line_map, objects
  end

  private
  def push(i, type, line_map, objects)
    #return false if line_map[i]
    #puts "---push, i = #{i}, type=#{type}, line_map = #{line_map}"

    if 1 == line_map[i]
      #puts "push: returning nil,  #{i} taken"
      nil
    elsif (dir, len = type; dir == :e)
      objects << type << i
      #puts "push : returning #{line_map}"
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

  def push_position(objects)
    rows_scheme     = Array.new(@size) { [] }
    columns_scheme  = Array.new(@size) { [] }
    rows_filling    = Array.new(@size) { [] }
    columns_filling = Array.new(@size) { [] }
    while objects.size > 0 do
      type, i = objects.pop 2
      dir, len = type
      next if dir == :e
      y = i / @size
      x = i % @size
      if dir == :h
        rows_scheme[y] << len
        rows_filling[y] << x
      else
        columns_scheme[x] << len
        columns_filling[x] << y
      end
    end
    @cache.store pack_scheme(rows_scheme, columns_scheme),
                 pack_filling(rows_filling, columns_filling)
  end

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

  public
  def fill_line(line_map, cell_nums)
    cell_nums.each{|x| line_map|=(1<<x)}
    line_map
  end

end