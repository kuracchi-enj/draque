require 'json'
require 'io/console'
require_relative 'renderer'
require_relative 'shop'
require_relative 'inn'
require_relative 'church'
require_relative 'castle'
require_relative 'npc'

class Town
  DATA_PATH = File.join(__dir__, '..', 'data', 'towns.json')

  PASSABLE = {
    '.' => true,
    'W' => true,
    'A' => true,
    'I' => true,
    'H' => true,
    'C' => true,
    'K' => true,
    'N' => true,
    'X' => true,
    '#' => false
  }.freeze

  def self.all
    @all ||= JSON.parse(File.read(DATA_PATH))
  end

  def self.[](area_key)
    data = all[area_key] || raise("未知の街データ: #{area_key}")
    new(area_key, data)
  end

  def initialize(area_key, data)
    @area_key = area_key
    @data     = data
    @map_grid = data['map'].map(&:chars)
  end

  def enter(player, area_data)
    @player    = player
    @area_data = area_data
    pos = @data['player_start'].dup

    loop do
      draw(pos)
      input = read_key

      break if %w[q quit exit].include?(input)

      new_pos = move(pos, input)
      next unless new_pos
      nx, ny = new_pos
      next unless valid?(nx, ny)

      tile = @map_grid[ny][nx]
      case tile
      when 'X'
        break
      when '.'
        pos = new_pos
      else
        pos = new_pos
        handle_tile(tile, nx, ny)
      end
    end
  end

  private

  TILE_DISPLAY = {
    'W' => -> { Renderer.yellow('W') },
    'A' => -> { Renderer.cyan('A') },
    'I' => -> { Renderer.green('I') },
    'H' => -> { Renderer.blue('H') },
    'C' => -> { Renderer.white('C') },
    'K' => -> { Renderer.magenta('K') },
    'N' => -> { Renderer.green('N') },
    'X' => -> { Renderer.yellow('X') },
    '#' => -> { Renderer.color('█', 90) },
    '.' => -> { '.' }
  }.freeze

  def draw(pos)
    Renderer.clear
    px, py = pos
    puts "  ══ #{@data['name']} ══   HP:#{@player.hp}/#{@player.max_hp}  MP:#{@player.mp}/#{@player.max_mp}  G:#{@player.gold}"
    puts ""

    @map_grid.each_with_index do |row, y|
      print "  |"
      row.each_with_index do |tile, x|
        if x == px && y == py
          print Renderer.bold(Renderer.yellow('P'))
        else
          fn = TILE_DISPLAY[tile]
          print fn ? fn.call : tile
        end
      end
      puts "|"
    end

    puts ""
    puts "  W:武器  A:防具  I:道具  H:宿屋  C:教会  K:城  X:出口"
    puts "  [wasd]移動  [q]退出"
    print "  > "
  end

  def handle_tile(tile, x, y)
    case tile
    when 'W' then Shop.new(@player, @area_data).open_weapons
    when 'A' then Shop.new(@player, @area_data).open_armors
    when 'I' then Shop.new(@player, @area_data).open_items
    when 'H' then Inn.new(@player, @area_data).open
    when 'C' then Church.new(@player).open
    when 'K' then Castle.new(@player).enter
    when 'N' then talk_to_npc(x, y)
    end
  end

  def talk_to_npc(x, y)
    entry = @data['npcs'].find { |n| n['x'] == x && n['y'] == y }
    NPC.talk(entry['npc_id']) if entry
  end

  def read_key
    first = STDIN.getch rescue (return gets.chomp.strip.downcase)
    return first.downcase if %w[w a s d].include?(first.downcase)
    print first
    rest = gets
    return '' if rest.nil?
    (first + rest).chomp.strip.downcase
  end

  def move(pos, input)
    x, y = pos
    case input
    when 'w', 'W' then [x, y - 1]
    when 's', 'S' then [x, y + 1]
    when 'a', 'A' then [x - 1, y]
    when 'd', 'D' then [x + 1, y]
    end
  end

  def valid?(x, y)
    return false unless y.between?(0, @map_grid.size - 1)
    return false unless x.between?(0, @map_grid[0].size - 1)
    PASSABLE.fetch(@map_grid[y][x], false)
  end
end
