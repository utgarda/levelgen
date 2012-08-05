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

    def initialize(size, rows, columns)
      @size = size
      @rows = rows.clone.freeze
      @columns = columns.clone.freeze
      @rows_maps = @rows.map{|r| map_string r}.freeze
      @columns_maps = @columns.map{|c| map_string c}.freeze
    end

    def map_string(blocks)
      return EMPTY_PERMUTATIONS_HASH if blocks.empty?

      variants = enum_string_variants 0, blocks
      maps_to_permutations = {}

      variants.each do |v|
        line_map = line_map_by_blocks_positions(blocks, v)
        connections = []
        blocks.each_index do |i|
          index_to_be_filled = v[i] - 1
          if index_to_be_filled >= 0 && line_map[index_to_be_filled].zero?
            (neigbour_positions = v.clone)[i] -= 1
            connections << [line_map_by_blocks_positions(blocks, neigbour_positions), index_to_be_filled]
          end
          index_to_be_filled = v[i] + blocks[i]
          if index_to_be_filled < @size && line_map[index_to_be_filled].zero?
            (neigbour_positions = v.clone)[i] += 1
            connections << [line_map_by_blocks_positions(blocks, neigbour_positions), index_to_be_filled]
          end
        end
        maps_to_permutations[line_map] = LinePermutation.new(v, connections)
      end
      maps_to_permutations.freeze
    end


  def line_map_by_blocks_positions(sizes, positions)
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

class Position

end

end

s = PositionsBFS::Scheme.new 10, [], []
pp  positions = s.enum_string_variants(0, [3,3])
positions.each{|p| puts s.line_map_by_blocks_positions([3,3],p).to_s 2}

pp s.map_string [3,3]