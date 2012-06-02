# encoding: utf-8
module TerminalOutput
  require 'rubygems'
  require 'ffi-ncurses'
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

  def render_objects(size, objects, empty_cell="*")
    line_map = Array.new size**2, empty_cell
    objects = objects.clone
    until objects.empty?
      type, i = objects.pop 2
      dir,len = type.to_s.split //, 2
      len = len.to_i
      filler = (horizontal = 'h' == dir) ? '~' : 'i'
      len.times do |x|
        line_map[ i + x * (horizontal ? 1 : size)] = filler
      end
    end
    puts "╔#{'═'*size}╗"
    until line_map.empty?
      puts "║#{line_map.pop(size).join}║"
    end
    puts "╚#{'═'*size}╝"
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