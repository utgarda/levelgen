
module TerminalOutput
  require 'rubygems'
  require 'ffi-ncurses'
  include FFI::NCurses

  def init(size)
    initscr
    curs_set 0
    win = newwin(size+2, size+2, 3, 3)
    box(win, 0, 0)
    @inner_win = newwin(size, size, 4, 4)
    wrefresh(win)
    wrefresh(@inner_win)
    @scheme_win = newwin(1,50,0,0)
  end

  def show_position(stage, scheme, filling, empty_space = "*")
    line_map = Array.new stage.size**2, empty_space
    rows, columns = scheme
    #TODO move ncurses representation string generation to Stage
    rows.each_index do |r|
      rows[r].each do |len|
        pos=filling.shift
        type = [:h, len]
        k = r * stage.size + pos
        stage.fill_line line_map, type, k,  "~"
      end
    end
   columns.each_index do |c|
     columns[c].each do |len|
       pos = filling.shift
       type = [:v, len]
       k = pos * stage.size + c
       stage.fill_line line_map, type, k, "i"
     end
   end
    wclear @scheme_win
    waddstr @scheme_win, scheme.inspect
    wrefresh @scheme_win
    wclear @inner_win
    waddstr @inner_win, line_map.join('')
    wrefresh @inner_win
    wgetch @inner_win
  end
end