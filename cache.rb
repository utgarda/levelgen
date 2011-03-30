class Cache
  def initialize(max_bucket_size = 10)
    @max_bucket_size = max_bucket_size
    @scheme_filling_map = Hash.new { |hash, key| hash[key] = [] }
    Dir.mkdir("./db") unless File.exists? "./db"
  end

  def store(scheme, filling)
    list = @scheme_filling_map[scheme] << filling
    if list.size >= @max_bucket_size
      @scheme_filling_map[scheme] = []
      open('./db/scheme_' + scheme, 'a') {|f|
        list.each { |s| f.puts s }
      }
      GC.start
    end
  end
end
