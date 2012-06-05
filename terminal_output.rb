# encoding: utf-8
module TerminalOutput

  require 'rubygems'
  require 'term/ansicolor'
  require 'ffi-ncurses'
  require 'json'
  include FFI::NCurses

  def init_ncurses(size)
    initscr
    curs_set 0
    win = newwin(size+2, size+2, 3, 3)
    box(win, 0, 0)
    $inner_win = newwin(size, size, 4, 4)
    wrefresh(win)
    wrefresh($inner_win)
    $scheme_win = newwin(1, 50, 0, 0)
  end
  
  def pause
    wgetch $inner_win
    # wrefresh $inner_win
  end
  
  def show_outline(outline)
    # wclear @scheme_win
    # waddstr @scheme_win, scheme.inspect
    # wrefresh @scheme_win
    
    i = outline & 255    
    wclear $inner_win
    waddstr $inner_win, "*"*(i)
    waddstr $inner_win, (outline >> 8).to_s(2).reverse

    
    wrefresh $inner_win
    #wgetch @inner_win
  end

  def self.render_objects(size, objects, empty_cell="*")
    columns = 10
    @@buffer ||= []
    c = Term::ANSIColor
    colors = [c.blue + c.on_yellow,
              c.white + c.on_blue,
              c.green + c.on_black,
              c.black + c.on_cyan,
              c.cyan + c.on_red,
              c.yellow + c.on_magenta
    ]
    line_map = Array.new size**2, empty_cell
    objects = objects.clone
    c = 0
    until objects.empty?
      type, i = objects.shift 2
      dir,len = type.to_s.split //, 2
      len = len.to_i
      filler = (horizontal = 'h' == dir) ? "~" : "i"
      len.times do |x|
        line_map[ i + x * (horizontal ? 1 : size)] = colors[c%6] + filler + Term::ANSIColor.clear
      end
      c += 1
    end
    if @@buffer.size == columns
      concatenated = Array.new(size+2){|x| []}
      @@buffer.each do |map|
        concatenated[0] << "╔#{'═'*size}╗"
        l = 1
        until map.empty?
          line = "║#{map.pop(size).join}║"
          concatenated[l] << line
          l += 1
        end
        concatenated[l] << "╚#{'═'*size}╝"
      end
      concatenated.each{ |lines|
        puts lines.join "  "}
      @@buffer = []
    else
      @@buffer << line_map
    end
  end

  #def show_position(stage, scheme, filling, empty_space = "*")
  #  line_map = Array.new stage.size**2, empty_space
  #  rows, columns = scheme
  #  #TODO move ncurses representation string generation to Stage
  #  rows.each_index do |r|
  #    rows[r].each do |len|
  #      pos  =filling.shift
  #      type = "h#{len}".to_sym
  #      k    = r * stage.size + pos
  #      Stage.fillLine line_map, type, k, "~"
  #    end
  #  end
  #  columns.each_index do |c|
  #    columns[c].each do |len|
  #      pos  = filling.shift
  #      type = "v#{len}".to_sym
  #      k    = pos * stage.size + c
  #      stage.fill_line line_map, type, k, "i"
  #    end
  #  end
  #  wclear $scheme_win
  #  waddstr $scheme_win, scheme.inspect
  #  wrefresh $scheme_win
  #  wclear $inner_win
  #  waddstr $inner_win, line_map.join('')
  #  wrefresh $inner_win
  #  wgetch $inner_win
  #end
end