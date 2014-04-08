require 'yaml'
require 'colorize'

class Board
  attr_accessor :grid, :grid_size

  def initialize(grid_size=9)
    @grid_size = grid_size
    @grid = Array.new(grid_size) { Array.new(grid_size) }
    populate_board(grid_size)
  end

  def populate_board(grid_size)
    (grid_size).times do |i|
      (grid_size).times do |j|
        @grid[i][j] = Tile.new([i,j], @grid)
      end
    end

    @grid.flatten.sample(@grid_size).each{|tile| tile.bomb = true}
  end

  def display
    puts "#" * (@grid_size + 1)*2 + "#"
    self.grid.each do |row|
      print "# "
      row.each do |el|
        print el.to_s + ' '
      end
      print "#"
      print "\n"
    end
    puts "#" * (@grid_size + 1)*2 + "#"
  end



end

class Minesweeper
  attr_accessor :boards

  def initialize
    @boards = Board.new
  end


  def play

    until over?

      self.boards.display

      puts "What tile would you like to reveal and would you like to flag it?"
      puts "x,y,f/r \nflag = f r = reveal\nq to quit"

      pos_and_move = gets.chomp
      y, x, move = pos_and_move.split('')
      if y == 'q'
        return true
      end
      x = x.to_i
      y = y.to_i
      if move == 'r'
        self.boards.grid[x][y].reveal(@boards)
      elsif move == 'f'
        self.boards.grid[x][y].flag
      end
    end

  end

  def over?

    flagged_bombs = 0
    explored_tiles = 0

    self.boards.grid.each do |row|
      row.each do |tile_obj|
        if tile_obj.status == :explored && tile_obj.bomb
          losing_message
          return true
        elsif tile_obj.status == :explored
          explored_tiles += 1
        elsif tile_obj.status == :flagged && tile_obj.bomb
          flagged_bombs += 1
        end
      end
    end

    if explored_tiles == (self.boards.grid.length ** 2 - self.boards.grid.length)
      winning_message
      return true
    elsif flagged_bombs == self.boards.grid.length
      winning_message
      return true
    end

    false
  end

  def losing_message
    puts "You Lost!"
  end

  def winning_message
    puts "You Won!"
  end

end

class Tile
  DELTAS = [[1, 0], [0, 1], [-1, 0], [0, -1], [1, 1], [-1, 1], [-1, -1], [1, -1]]
  attr_accessor :pos, :bomb, :grid, :status

  def initialize(pos, board)
    @status = :unexplored
    @grid = board
    @bomb = false
    @pos = pos
  end

  def to_s
    if self.status == :unexplored
      '*'
    elsif self.status == :flagged
      'F'
    else
      if self.neighbor_bomb_count == 0
        ' '
      else
        self.neighbor_bomb_count.to_s
      end
    end
  end

  def reveal(boards)
    return unless self.status == :unexplored
    self.status = :explored

    if (self.neighbor_bomb_count == 0)
      neighbors.each do |neighbor|
        neighbor.reveal(boards)
      end
    end
  end

  def neighbors
    neighbors = []
    DELTAS.each do |i,j|
      next unless [(self.pos[0] + i),(self.pos[1] + j)].all? do |coord|
        coord.between?(0, self.grid.length - 1)
      end
      # puts "grid is nil" if self.grid.nil?
      # puts "pos is nil" if self.pos.nil?
      # p self.pos[0] + i

      neighbors << self.grid[self.pos[0] + i][self.pos[1] + j]
    end
    if neighbors.length != neighbors.compact.length
      puts "WTF WHY ARE THERE NIL NEIGHBORS?"
    end
    neighbors
  end

  def flag
    self.status = :flagged
  end

  def neighbor_bomb_count
    count = self.neighbors.select do |neighbor|
      neighbor.bomb
    end.count
    count
  end
end

def minesweeper_extreme
  puts "Welcome to Minesweeper Enterprise EditionTM"
  puts "Enter a filename to load old game"
  filename = gets.chomp
  if filename.empty?
    game = Minesweeper.new
  else
    game = YAML.load_file(filename)
  end
  if game.play
    puts "Enter a filename to save game."
    filename = gets.chomp
    File.open(filename, 'w') { |file| file.write(game.to_yaml) }
  end
end