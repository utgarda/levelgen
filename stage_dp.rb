#require 'persistence'

class StageDP
  MAIN_OBJ_LENGTH = 2
  MAX_EMPTY_CELLS = 1

  attr_reader :size
  attr_reader :types
  attr_reader :positions

  class PartialSolution
    attr_reader :count
    def initialize(branch_map = {})
      @branches = branch_map #mapping object placement variants to sub-task results for the remaining outline
      @count = @branches.empty? ? 1 : @branch_map.values.map(&:count).reduce(:+)
    end
  end

  def initialize(size, object_length_range, cache)
    raise "Even-sized stages not implemented" unless size.odd?
    @size       = size
    @line_map_size = @size**2
    @array      = Array.new(@size) { [] }
    #@proper_map = Array.new(2) { Array.new(@size) { [] } }
    @types      = [[:e, 0].freeze]
    object_length_range.each { |i| @types += [[:h, i].freeze, [:v, i].freeze] }
    @types.freeze
    @cache      = cache
    @outline_to_solution = {(@line_map_size - 1) => PartialSolution.new}
#    Struct.new("State", :i, :line_map, :objects, :empty_cells)
  end

  def line_map_to_number(i, line_map)
    (line_map[i+1..-1].inject(0){|binary, cell| (cell ? 1 : 0) + (binary << 1)} << 8) + i
  end

  def iterate_solutions(i, empty_cells, line_map, objects)
    outline_code = line_map_to_number(i, line_map)

     if @outline_to_solution.has_key? outline_code
       #puts "+"
       @outline_to_solution[outline_code]
     #elsif i == @line_map_size # - 1
     # #return if empty_cells > MAX_EMPTY_CELLS
     # #@outline_to_solution[i, line_map]
     # puts "Error: cell number #{i} actually reached"
     # #push_position objects.clone
     # exit
     elsif line_map[i]
       #puts "--"
      #@outline_to_solution[outline_code] =
          iterate_solutions i+1, empty_cells, line_map, objects
     else
       #puts "New outline: i = #{i} , code = #{outline_code}, total outlines: #{@outline_to_solution.keys.size}"
       puts "i = #{i}" #" , total outlines: #{@outline_to_solution.keys.size}"
       @types.each { |t|
        if ( (t[0]!=:e) || (empty_cells<MAX_EMPTY_CELLS)) && (push i, t, line_map, objects)
          iterate_solutions i+1, empty_cells + (t[0] == :e ? 1 : 0), line_map, objects
          pop line_map, objects
        end
      }
       @outline_to_solution[outline_code] = PartialSolution.new #TODO
    end
  end

  def trivial_solution
    line_map = Array.new(@size**2, false)
    objects  = []
    push_main line_map, objects
    [line_map, objects]
  end

  private
  def push_main(line_map, objects)
    main_obj_type = [:h, MAIN_OBJ_LENGTH]
    push @size * (@size / 2 + 1) - MAIN_OBJ_LENGTH, main_obj_type, line_map, objects
  end

  private
  def push(i, type, line_map, objects)
    return false if line_map[i]

    dir, len = type

    if dir == :e
      objects << type << i
      return true
    end

    y = i / @size
    x = i % @size
    #check if the object fits inside the rectangle
    return false if (dir == :h ? x : y) + len > @size
    #check if all required space is free
    len.times do |k|
      return if line_map[i + k * (dir == :h ? 1 : @size)]
    end
    #other constraints


    objects << type << i
    fill_line line_map, type, i, true
    true
  end

  private
  def pop(line_map, objects)
    type, i = objects.pop 2
    dir = type[0]
    return if dir == :e
    fill_line line_map, type, i, false
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
#                              (rows_filling + columns_filling).flatten.pack("C*")
  end

  def pack_scheme(rows, columns)
#    (rows + columns).map { |x| x.pack "C*" }.join "," #works only if max object length < ?,
    (rows + columns).map { |x| x.join }.join ","
  end

  def pack_filling(rows, columns)
    (rows + columns).join
  end

  public
  def unpack_scheme(p_scheme)
#    scheme = p_scheme.split(/,/).map { |s| s.unpack "C*" }
    scheme = p_scheme.split(/,/).map { |s| s.split // }
    [scheme.slice!(0..@size-1), scheme]
  end

  public
  def fill_line(line_map, type, i, val)
    dir, len = type
    len.times { |k| line_map[i + k * (dir == :h ? 1 : @size)] = val }
  end

#
end