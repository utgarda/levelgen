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
  attr_reader :mainObject

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
        yield objects
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

  class Position
    #@@trivialSolutions = {}

    attr_reader :emptyCells
    attr_reader :lineMap
    attr_reader :objects

    def initialize(stage)
      @stage = stage
      @size = stage.size
      @types = stage.types
      @objects  = []
      @lineMap = 0
      @lineMapStack = []
      @emptyCells = 0
    end

    def self.trivial_solution(stage)
      p = Position.new(stage)
      p.push stage.size * (stage.size / 2 + 1) - MAIN_OBJ_LENGTH, stage.mainObject
      p
    end


    #def self.trivialSolution(stage)
    #  @@trivialSolutions[[stage.size,stage.mainObject]] ||= composeTrivialSolution(stage.size, stage.mainObject).freeze
    #end

    def push(i, type)
      if 1 == @lineMap[i]
        nil
      elsif (type == :e0)
        @objects << type << i
        @emptyCells += 1
        if block_given?
          yield next_free_position(i+1)
          pop
        end
      elsif (dir,len = @types[type]; (dir == :h ? i % @size : i / @size) + len > @size) #check if the object fits inside the rectangle
        nil
      elsif ( step = dir == :h ? 1 : @size;
              cellNums = Array.new(len) { |k| i + k * step };
              cellNums.any? { |k| @lineMap[k] == 1 }) #check if all required space is free
        nil
        #other constraints to check?
      else
        @objects << type << i
        @lineMapStack << @lineMap
        cellNums.each{|x| @lineMap|=(1<<x)}
        if block_given?
          yield next_free_position(i+1)
          pop
        end
      end
    end

    def next_free_position(i)
      i+=1 while 1 == @lineMap[i]
      i
    end

    def pop
      type, i = objects.pop 2
      if type == :e0
        @emptyCells-=1
      else
        @lineMap = @lineMapStack.pop
      end
    end

    #def self.composeTrivialSolution(size, mainObject)
    #  objects  = []
    #  lineMap = push size * (size / 2 + 1) - MAIN_OBJ_LENGTH, mainObject, 0, objects
    #  [lineMap, objects]
    #end
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
    @trivialSolution = Position.trivial_solution(self).freeze
    @trivialSolutionScheme = objectsMapToScheme(@trivialSolution.objects).freeze
    
    @trivialPartial = PartialSolution.new(@lineMapSize, {@trivialSolutionScheme => nil})
    @trivialOutline = @lineMapSize
    @outlineToSolution = { @trivialOutline   => @trivialPartial}
  end

  def lineMapToOutline(i, lineMap)
    ((lineMap >> (i)) << 8) + i
  end

  def iterateSolutions(i, position = Position.trivial_solution(self))
    outlineCode = lineMapToOutline(i, position.lineMap)
     if @outlineToSolution.has_key? outlineCode
       @outlineToSolution[outlineCode]
     elsif 1 == position.lineMap[i]
          iterateSolutions i+1, position
     else
       ssMap = {}
       @types.each_key do |t|
         unless  t==:e0 && position.emptyCells >= MAX_EMPTY_CELLS
           position.push(i, t) do |next_i|
             subSolution = iterateSolutions next_i, position
             subSolution.branches.each_key do |subScheme|
               s = addObjectToScheme i, t, subScheme
               ssMap[s]||={}
               ssMap[s][t] = [subSolution, subScheme]
             end
           end
         end
       end
       @outlineToSolution[outlineCode] = ssMap.empty? ? @trivialPartial : PartialSolution.new(i, ssMap)
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

end
