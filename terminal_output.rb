
module TerminalOutput
  require 'rubygems'
  require 'ffi-ncurses'
  include FFI::NCurses

  def init(size)
    initscr
    curs_set 0
    win = newwin(size+2, size+2, 1, 1)
    box(win, 0, 0)
    @inner_win = newwin(size, size, 2, 2)
    wrefresh(win)

    wrefresh(@inner_win)
  end

  def show_position(stage, scheme, filling, empty_space = "*")
    line_map = Array.new stage.size**2, empty_space
#    while objects.size > 0
#      type_num, i = objects.pop 2
#      dir = stage.types[type_num][0]
#      if dir != :e
#        stage.fill_line line_map, type_num, i, dir == :h ? "~" : "i"
#      end
#    end
   scheme.each_index do |i|
     scheme[i].each do |len|
       pos = filling.shift
       type_num = stage.types.index [i<stage.size ? :h : :v, len]
       k = i<stage.size ? i * stage.size + pos : (pos-1)* stage.size + i
       stage.fill_line line_map, type_num, k, i < stage.size ? "~" : "i"
     end
   end

    wclear(@inner_win)
    waddstr(@inner_win, line_map.join(''))
    wrefresh(@inner_win)
    puts line_map.size
    ch = wgetch(@inner_win)
  end
end