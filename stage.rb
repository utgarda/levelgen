class Stage
  MAIN_OBJ_LENGTH = 2

  attr_reader :size
  attr_reader :types
  attr_reader :positions

  def initialize(size, object_length_range)
    raise "Even-sized stages not implemented" unless size.odd?
    @size       = size
    @array      = Array.new(@size) { [] }
    @proper_map = Array.new(2) { Array.new(@size) { [] } }
    @types      = [[:e, 0]]
    object_length_range.each { |i| @types += [[:h, i], [:v, i]] }
    @types.freeze
    @positions = Hash.new{|h,k| h[k]=[]}
  end


  def iterate_solutions(i, line_map, objects)
#    return if @positions.size > 100
    if i == @size**2 - 1
      push_position objects.clone
      return
    end
    if line_map[i]
      iterate_solutions i+1, line_map, objects
    else
      @types.each_index { |tn|
        if push i, tn, line_map, objects
          iterate_solutions i+1, line_map, objects
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
    main_obj_type = @types.index([:h, MAIN_OBJ_LENGTH])
    push @size * (@size / 2 + 1) - MAIN_OBJ_LENGTH, main_obj_type, line_map, objects
  end

  private
  def push(i, type_num, line_map, objects)
    return false if line_map[i]

    dir, len = @types[type_num]

    if dir == :e
      objects << type_num << i
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
    objects << type_num << i
    fill_line line_map, type_num, i, true
    true
  end

  private
  def pop(line_map, objects)
    type_num, i   = objects.pop 2
    dir = @types[type_num][0]
    return if dir == :e
    fill_line line_map, type_num, i, false
  end

  def push_position(objects)
    rows_scheme = Array.new(@size){[]}
    columns_scheme = Array.new(@size){[]}
    rows_filling = Array.new(@size){[]}
    columns_filling = Array.new(@size){[]}
    while objects.size > 0 do
      type_num, i   = objects.pop 2
      dir,len = @types[type_num]
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
    scheme = rows_scheme += columns_scheme
    filling = rows_filling += columns_filling
    @positions[scheme.freeze] << filling.flatten.freeze
  end


  public
  def fill_line(line_map, type_num, i, val)
    dir, len = @types[type_num]
    len.times { |k| line_map[i + k * (dir == :h ? 1 : @size)] = val }
  end


end