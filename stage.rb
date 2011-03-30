#require 'persistence'

class Stage
  MAIN_OBJ_LENGTH = 2
  MAX_EMPTY_CELLS = 10

  attr_reader :size
  attr_reader :types
  attr_reader :positions

  def initialize(size, object_length_range, cache)
    raise "Even-sized stages not implemented" unless size.odd?
    @size       = size
    @array      = Array.new(@size) { [] }
    @proper_map = Array.new(2) { Array.new(@size) { [] } }
    @types      = [[:e, 0].freeze]
    object_length_range.each { |i| @types += [[:h, i].freeze, [:v, i].freeze] }
    @types.freeze
    @cache      = cache
#    Struct.new("State", :i, :line_map, :objects, :empty_cells)
  end


  def iterate_solutions(i, empty_cells, line_map, objects)
    return if empty_cells > MAX_EMPTY_CELLS
    if i == @size**2 - 1
      push_position objects.clone
      return
    end
    if line_map[i]
      iterate_solutions i+1, empty_cells, line_map, objects
    else
      @types.each { |t|
        if push i, t, line_map, objects
          iterate_solutions i+1, empty_cells + (t[0] == :e ? 1 : 0), line_map, objects
          pop line_map, objects
        end
      }
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