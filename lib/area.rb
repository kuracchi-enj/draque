require 'json'

class Area
  DATA_PATH = File.join(__dir__, '..', 'data', 'areas.json')

  TILE_PASSABLE = {
    '.' => true,
    'T' => true,
    'B' => true,
    '#' => false,
    '~' => false
  }.freeze

  attr_reader :key, :name, :map_grid, :player_start, :town_pos, :boss_pos,
              :town_name, :data

  def self.all
    @all ||= JSON.parse(File.read(DATA_PATH))
  end

  def self.[](key)
    new(key, all[key] || raise("未知のエリア: #{key}"))
  end

  def self.next_key(current)
    { 'A' => 'B', 'B' => 'C' }[current]
  end

  def initialize(key, data)
    @key          = key
    @data         = data
    @name         = data['name']
    @map_grid     = data['map'].map(&:chars)
    @player_start = data['player_start']
    @town_pos     = data['town_pos']
    @boss_pos     = data['boss_pos']
    @town_name    = data['town_name']
  end

  def passable?(x, y)
    return false unless y.between?(0, @map_grid.size - 1)
    return false unless x.between?(0, @map_grid[0].size - 1)
    TILE_PASSABLE.fetch(@map_grid[y][x], false)
  end

  def tile_at(x, y)
    @map_grid[y][x]
  end

  def width
    @map_grid[0].size
  end

  def height
    @map_grid.size
  end
end
