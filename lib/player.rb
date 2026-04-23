require_relative 'job'
require_relative 'inventory'

class Player
  EXP_TABLE = (1..99).map { |lv| (lv ** 3 * 0.5).ceil }.freeze

  attr_accessor :name, :job_name, :level, :exp, :gold, :hp, :mp,
                :current_area, :position, :defeated_bosses,
                :inventory, :atk_buff, :def_buff, :status_effects,
                :treasures

  def initialize(name:, job_name:)
    @name            = name
    @job_name        = job_name
    @level           = 1
    @exp             = 0
    @gold            = 50
    @current_area    = 'A'
    @position        = nil
    @defeated_bosses = []
    @inventory       = Inventory.new
    @atk_buff        = 0
    @def_buff        = 0
    @status_effects  = {}
    @treasures       = {}

    base = current_stats
    @hp = base['hp']
    @mp = base['mp']
  end

  def job
    Job[@job_name]
  end

  def current_stats
    job.stats_at(@level)
  end

  def max_hp
    current_stats['hp']
  end

  def max_mp
    current_stats['mp']
  end

  def base_atk
    current_stats['atk']
  end

  def base_def
    current_stats['def']
  end

  def base_agi
    current_stats['agi']
  end

  def total_attack
    base_atk + @inventory.weapon_bonus('atk_bonus') + @atk_buff
  end

  def total_defense
    base_def + @inventory.armor_bonus('def_bonus') + @def_buff
  end

  def total_agility
    base_agi + @inventory.weapon_bonus('agi_bonus')
  end

  def learned_spells
    job.spells_learned_by(@level)
  end

  def alive?
    @hp > 0
  end

  def heal_hp(amount)
    @hp = [@hp + amount, max_hp].min
  end

  def heal_mp(amount)
    @mp = [@mp + amount, max_mp].min
  end

  def take_damage(amount)
    @hp = [@hp - amount, 0].max
  end

  def use_mp(amount)
    @mp -= amount
  end

  def exp_to_next
    return nil if @level >= 99
    EXP_TABLE[@level] - @exp
  end

  def gain_exp(amount)
    messages = []
    @exp += amount
    while @level < 99 && @exp >= EXP_TABLE[@level]
      @level += 1
      old_hp = max_hp
      old_mp = max_mp
      base = current_stats
      @hp  = [base['hp'], @hp + (base['hp'] - old_hp)].min
      @mp  = [base['mp'], @mp + (base['mp'] - old_mp)].min
      messages << "レベルが #{@level} に上がった！"
      spell_news = job.spells_learned_by(@level).select { |s| s['learn_lv'] == @level }
      spell_news.each { |s| messages << "呪文「#{s['name']}」を覚えた！" }
    end
    messages
  end

  def gain_gold(amount)
    @gold += amount
  end

  def spend_gold(amount)
    raise '所持金が足りない' if @gold < amount
    @gold -= amount
  end

  def reset_buffs
    @atk_buff = 0
    @def_buff = 0
  end

  # Called when an enemy uses a defense-reducing spell (e.g. ルカニ) on the player.
  def apply_def_debuff(rate)
    @def_buff -= (base_def * rate).round
  end

  def status_summary
    return '' if @status_effects.empty?
    require_relative 'status_effect'
    @status_effects.keys.map { |e| StatusEffect::NAMES[e] || e.to_s }.join('/')
  end

  def to_h
    {
      'name'            => @name,
      'job_name'        => @job_name,
      'level'           => @level,
      'exp'             => @exp,
      'gold'            => @gold,
      'hp'              => @hp,
      'mp'              => @mp,
      'current_area'    => @current_area,
      'position'        => @position,
      'defeated_bosses' => @defeated_bosses,
      'inventory'       => @inventory.to_h,
      'status_effects'  => @status_effects.transform_keys(&:to_s),
      'treasures'       => @treasures
    }
  end

  def self.from_h(h)
    p = new(name: h['name'], job_name: h['job_name'])
    p.level           = h['level']
    p.exp             = h['exp']
    p.gold            = h['gold']
    p.hp              = h['hp']
    p.mp              = h['mp']
    p.current_area    = h['current_area']
    p.position        = h['position']
    p.defeated_bosses = h['defeated_bosses'] || []
    p.inventory       = Inventory.from_h(h['inventory'])
    p.status_effects  = (h['status_effects'] || {}).transform_keys(&:to_sym)
    p.treasures       = h['treasures'] || {}
    p
  end
end
