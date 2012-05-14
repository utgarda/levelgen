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
  attr_reader :trivialSolutionScheme
  attr_reader :outlineToSolution

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
    @lineMapSize = @size**2

    @types = {@emptyCell = :e0 => [:e, 0].freeze,
              @mainObject = "h#{MAIN_OBJ_LENGTH}".to_sym => [:h, MAIN_OBJ_LENGTH].freeze
    }
    objectLengthRange.each do |i|
      @types.merge!({ "h#{i}".to_sym => [:h, i].freeze,
                      "v#{i}".to_sym => [:v, i].freeze })
    end
    @types.freeze

    #@emptyScheme = packScheme(a=Array.new(@size){[]}, a)
    @trivialSolution = composeTrivialSolution().freeze
    @trivialSolutionScheme = objectsMapToScheme(@trivialSolution[1]).freeze
    
    @trivialPartial = PartialSolution.new(@lineMapSize, {@trivialSolutionScheme => nil})
    @trivialOutline = @lineMapSize
    @outlineToSolution = { @trivialOutline   => @trivialPartial}
  end

  def lineMapToOutline(i, lineMap)
    ((lineMap >> (i)) << 8) + i
  end

  def iterateSolutions(i, emptyCells, lineMap, objects)
    outlineCode = lineMapToOutline(i, lineMap)
     if @outlineToSolution.has_key? outlineCode
       @outlineToSolution[outlineCode]
     elsif 1 == lineMap[i]
          iterateSolutions i+1, emptyCells, lineMap, objects
     else
       ssMap = {}
       @types.each_key do |t|
         unless  t==:e0 && emptyCells >= MAX_EMPTY_CELLS
           nextLineMap = push i, t, lineMap, objects
           if nextLineMap
             subSolution = iterateSolutions i+1, emptyCells + (t == :e0 ? 1 : 0), nextLineMap, objects
             subSolution.branches.each_key do |subScheme|
               s = addObjectToScheme i, t, subScheme
               ssMap[s]||={}
               ssMap[s][t] = [subSolution, subScheme]
             end
           end
           objects.pop 2
         end
       end
       @outlineToSolution[outlineCode] = ssMap.empty? ? @trivialPartial : PartialSolution.new(i, ssMap)
    end
  end

  def composeTrivialSolution
    objects  = []
    lineMap = push @size * (@size / 2 + 1) - MAIN_OBJ_LENGTH, @mainObject, 0, objects
    [lineMap, objects]
  end

  private
  def push(i, type, lineMap, objects)
    if 1 == lineMap[i]
      nil
    elsif (dir, len = @types[type]; dir == :e)
      objects << type << i
      lineMap
    elsif (y = i / @size; x = i % @size; (dir == :h ? x : y) + len > @size) #check if the object fits inside the rectangle
      nil
    elsif (cellNums = Array.new(len) { |k| i + k * (dir == :h ? 1 : @size) };
          cellNums.any? { |k| lineMap[k] == 1 }) #check if all required space is free
      nil
      #other constraints to check?
    else
      objects << type << i
      fillLine lineMap, cellNums
    end
  end

  def packScheme(rows, columns)
    (rows + columns).map { |x| (x || []).join }.join(",").to_sym
  end

  public
  def unpackScheme(p_scheme)
    scheme = p_scheme.to_s.split(/,/ , -1).map {|s| s.split // }
    #scheme = p_scheme.to_s.split(/,/).map { s.split // } #early optimization is so evil!
    [scheme.slice!(0..@size-1), scheme]
  end
  
  def addObjectToScheme(i, type, scheme)
    dir, len = @types[type]
    return scheme if dir == :e
    y = i / @size
    x = i % @size    
    rows, columns = unpackScheme(scheme)
    rows ||= []
    columns ||= []    
    (dir == :h ? (rows[y]||=[]) : (columns[x]||=[])).unshift len
    packScheme rows, columns
  end

  def objectsMapToScheme(objects)
    objects = objects.clone
    rowsScheme     = Array.new(@size) { [] }
    columnsScheme  = Array.new(@size) { [] }
    until objects.empty? do
      type, i = objects.pop 2
      dir, len = @types[type]
      next if dir == :e
      y = i / @size
      x = i % @size
      if dir == :h
        rowsScheme[y] << len
      else
        columnsScheme[x] << len
      end
    end
    packScheme rowsScheme, columnsScheme
  end

  public
  def fillLine(lineMap, cell_nums)
    cell_nums.each{|x| lineMap|=(1<<x)}
    lineMap
  end
end
