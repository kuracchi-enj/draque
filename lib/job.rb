require 'json'

class Job
  DATA_PATH = File.join(__dir__, '..', 'data', 'jobs.json')
  SPELLS_PATH = File.join(__dir__, '..', 'data', 'spells.json')

  KEY_LEVELS = [1, 10, 20, 50, 80, 99].freeze

  attr_reader :name, :description, :can_cast, :allowed_weapons, :allowed_armor_types

  def self.all
    @all ||= JSON.parse(File.read(DATA_PATH))
                 .each_with_object({}) { |(name, d), h| h[name] = new(name, d) }
  end

  def self.spells_data
    @spells_data ||= JSON.parse(File.read(SPELLS_PATH))
  end

  def self.[](name)
    all[name] || raise("未知の職業: #{name}")
  end

  def initialize(name, data)
    @name             = name
    @description      = data['description']
    @can_cast         = data['can_cast']
    @allowed_weapons  = data['allowed_weapons']
    @allowed_armor_types = data['allowed_armor_types']
    @key_stats = data['stats'].transform_keys(&:to_i)
  end

  def stats_at(level)
    level = level.clamp(1, 99)
    lower_lv = KEY_LEVELS.select { |l| l <= level }.max
    upper_lv = KEY_LEVELS.select { |l| l >= level }.min

    return @key_stats[lower_lv].dup if lower_lv == upper_lv

    lo = @key_stats[lower_lv]
    hi = @key_stats[upper_lv]
    t  = (level - lower_lv).to_f / (upper_lv - lower_lv)

    %w[hp mp atk def agi].each_with_object({}) do |k, h|
      h[k] = (lo[k] + (hi[k] - lo[k]) * t).round
    end
  end

  def spells_learned_by(level)
    return [] unless @can_cast
    (Job.spells_data[@name] || []).select { |s| s['learn_lv'] <= level }
  end

  def can_equip_weapon?(weapon)
    allowed_weapons.include?(weapon['type'])
  end

  def can_equip_armor?(armor)
    allowed_armor_types.include?(armor['armor_type'])
  end
end
