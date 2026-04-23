require 'json'

class Monster
  DATA_PATH = File.join(__dir__, '..', 'data', 'monsters.json')

  attr_reader :name, :max_hp, :max_mp, :atk, :agi, :exp, :gold, :drops,
              :elements, :spells, :status_attacks, :status_resist_table
  attr_accessor :hp, :mp, :status_effects, :def_debuff

  def self.data
    @data ||= JSON.parse(File.read(DATA_PATH))
  end

  def self.random_for_area(area_key)
    normal = data[area_key]['normal']
    new(normal.sample)
  end

  def self.boss_for_area(area_key)
    new(data[area_key]['boss'])
  end

  def initialize(data)
    @name               = data['name']
    @max_hp             = data['hp']
    @hp                 = data['hp']
    @max_mp             = data['mp'] || 0
    @mp                 = @max_mp
    @atk                = data['atk']
    @base_def           = data['def']
    @agi                = data['agi']
    @exp                = data['exp']
    @gold               = data['gold']
    @drops              = data['drops'] || []
    @elements           = data['elements'] || {}
    @spells             = data['spells'] || []
    @status_attacks     = (data['status_attacks'] || []).map(&:to_sym)
    @status_resist_table = data['status_resist'] || {}
    @status_effects     = {}
    @def_debuff         = 0
  end

  # base def keyword workaround: expose as def via method_missing is not needed;
  # attr_reader :def doesn't work since def is reserved. Use this method instead.
  def def
    [@base_def - @def_debuff, 0].max
  end

  def alive?
    @hp > 0
  end

  def take_damage(amount)
    @hp = [@hp - amount, 0].max
  end

  def use_mp(amount)
    @mp = [@mp - amount, 0].max
  end

  def resist_rate(element)
    @elements[element.to_s] || 1.0
  end

  def status_resist(effect)
    @status_resist_table[effect.to_s] || 0.0
  end

  def instant_death_resist
    status_resist(:instant_death)
  end

  def apply_def_debuff(rate)
    @def_debuff = (@base_def * rate).round
  end

  def status_summary
    return '' if @status_effects.empty?
    require_relative 'status_effect'
    @status_effects.keys.map { |e| StatusEffect::NAMES[e] || e.to_s }.join('/')
  end

  def roll_drops
    result = []
    @drops.each do |drop|
      result << drop if rand < drop['rate']
    end
    result
  end
end
