require 'pp'

class PositionsBFS


  class Scheme

    class LinePermutation
      attr_reader :blocks_positions
      attr_reader :leads_to

      def initialize(blocks_positions, connections)
        @blocks_positions = blocks_positions.clone.freeze
        @leads_to = connections.clone.freeze
        freeze
      end
    end

    EMPTY_PERMUTATION = LinePermutation.new([],[])
    EMPTY_PERMUTATIONS_HASH={0 => EMPTY_PERMUTATION}.freeze

    attr_reader :size
    attr_reader :blocks_to_maps
    attr_reader :rows_and_columns
    attr_reader :maps_to_permutations_array

    def initialize(size, rows, columns)
      @size = size
      @blocks_to_maps =  Hash.new {|h,k| h[k] = map_string(k)}
      @rows, @columns = [], []
      @maps_to_permutations_array = [] #TODO duplicates @blocks_to_maps
      [[@rows, rows], [@columns, columns]].each do |var, arg|
        arg.each do |r|
          @blocks_to_maps[r]
          var << @blocks_to_maps.assoc(r)[0]
          @maps_to_permutations_array << @blocks_to_maps.assoc(r)[1]
          #puts @blocks_to_maps.assoc(r).to_s
        end
      end
      @rows.freeze
      @columns.freeze
      @rows_and_columns = (@rows + @columns).freeze
      @blocks_to_maps.freeze
      @maps_to_permutations_array.freeze
      freeze
    end

    def map_string(blocks)
      return EMPTY_PERMUTATIONS_HASH if blocks.empty?

      variants = enum_string_variants 0, blocks
      maps_to_permutations = {}

      variants.each do |v|
        line_map = self.class.line_map_by_blocks_positions(blocks, v)
        connections = []
        blocks.each_index do |i|
          index_to_be_filled = v[i] - 1
          if index_to_be_filled >= 0 && line_map[index_to_be_filled].zero?
            (neigbour_positions = v.clone)[i] -= 1
            connections << [self.class.line_map_by_blocks_positions(blocks, neigbour_positions), index_to_be_filled]
          end
          index_to_be_filled = v[i] + blocks[i]
          if index_to_be_filled < @size && line_map[index_to_be_filled].zero?
            (neigbour_positions = v.clone)[i] += 1
            connections << [self.class.line_map_by_blocks_positions(blocks, neigbour_positions), index_to_be_filled]
          end
        end
        maps_to_permutations[line_map] = LinePermutation.new(v, connections)
      end
      maps_to_permutations.freeze
    end


  def self.line_map_by_blocks_positions(sizes, positions)
    line_map = 0
    sizes.each_index do |i|
      sizes[i].times{ |k| line_map |= (1 << (k+positions[i])) }
    end
    line_map
  end

  def enum_string_variants(start, blocks, positions = Hash[ Array.new(@size+1){|i| [[i,[]],[[]] ]} ])
    return positions[ [start, blocks] ]  if positions.has_key? [start,blocks]
    result = nil
    (@size - start - blocks.reduce(&:+) + 1).times do |i|
      sub_positions = enum_string_variants start+i+blocks[0], blocks[1..-1], positions
      (result ||=[]).concat sub_positions.map{ |sp| sp.clone.unshift( i+start ) }  unless sub_positions.nil?
    end
    positions[ [start,blocks] ] = result
  end

end

  def initialize(stage, scheme_array)
    @stage = stage
    @scheme = Scheme.new @stage.size, scheme_array[0], scheme_array[1]
  end

  def position_from_objects_array(objects)
    objects = objects.clone
    rows     = Array.new(@stage.size) { [] }
    columns  = Array.new(@stage.size) { [] }
    until objects.empty? do
      type, i = objects.pop 2
      dir, len = @stage.types[type]
      next if dir == :e
      y = i / @stage.size
      x = i % @stage.size
      if dir == :h
        rows[y] << x
      else
        columns[x] << y
      end
    end
    positions = rows + columns
    line_maps = []
    @scheme.rows_and_columns.each_index do |i|
      line_maps << Scheme.line_map_by_blocks_positions(@scheme.rows_and_columns[i], positions[i])
    end
    line_maps
  end

  # yields with adjacent positions as arguments, one at a time,
  # don't change, clone for further usage if required
  def find_adjacent(position)
    [0,1].each do |k|
      offset = k * @scheme.size
      cross_offset = (k + 1) % 2 * @scheme.size
      @scheme.size.times do |i|
        index = offset + i
        line_permutation = @scheme.maps_to_permutations_array[index][position[index]]
        line_permutation.leads_to.each do |line_map, index_to_be_filled|
          if position[cross_offset + index_to_be_filled][i].zero?
            l, position[index] = position[index], line_map
            yield position
            position[index] = l
          end
        end
      end
    end
  end


end

s = PositionsBFS::Scheme.new 10, [], []
pp  positions = s.enum_string_variants(0, [3,3])
positions.each{|p| puts PositionsBFS::Scheme.line_map_by_blocks_positions([3,3],p).to_s 2}

pp s.map_string [3,3]