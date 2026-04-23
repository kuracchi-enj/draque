require_relative 'status_effect'

class Spell
  # Cast a spell. Returns array of result messages.
  #
  # caster  - the entity casting the spell (Player or Monster)
  # spell_data - the spell definition hash
  # targets - array of targets (enemies)
  # self_target - the caster themselves (for heal/buff effects)
  def self.cast(caster, spell_data, targets: [], self_target: nil)
    effect  = spell_data['effect']
    element = spell_data['element']
    me = self_target || caster

    case effect
    when 'heal_hp'
      healed = [me.max_hp - me.hp, spell_data['amount']].min
      me.heal_hp(spell_data['amount'])
      ["#{me.name} のHPが #{healed} 回復した！"]

    when 'heal_hp_full'
      healed = me.max_hp - me.hp
      me.heal_hp(9999)
      ["#{me.name} のHPが完全に回復した！"]

    when 'damage_single'
      t = targets.first
      return ["対象がいない！"] unless t
      [damage_message(caster, t, spell_data, element)]

    when 'damage_all'
      return ["対象がいない！"] if targets.empty?
      targets.map { |t| damage_message(caster, t, spell_data, element) }

    when 'instant_death'
      t = targets.first
      return ["対象がいない！"] unless t
      resist = t.respond_to?(:status_resist) ? t.status_resist(:instant_death) : 0.0
      rate   = spell_data['rate'] * (1.0 - resist)
      if rand < rate
        t.take_damage(t.hp)
        ["#{t.name} は倒れた！"]
      else
        ["しかし効果がなかった..."]
      end

    when 'buff_atk'
      me.atk_buff += me.base_atk
      ["#{me.name} の攻撃力が上がった！"]

    when 'buff_def'
      me.def_buff += me.base_def
      ["#{me.name} の防御力が上がった！"]

    when 'debuff_def'
      t = targets.first
      return ["対象がいない！"] unless t
      t.apply_def_debuff(spell_data['rate'] || 0.5)
      ["#{t.name} の防御力が下がった！"]

    when 'sleep'
      t = targets.first
      return ["対象がいない！"] unless t
      resist = t.respond_to?(:status_resist) ? t.status_resist(:sleep) : 0.0
      if rand > resist
        msg = StatusEffect.apply(t, :sleep, spell_data['turns'] || 3)
        [msg || "#{t.name} は眠ってしまった！"]
      else
        ["しかし効果がなかった..."]
      end

    when 'blind'
      t = targets.first
      return ["対象がいない！"] unless t
      resist = t.respond_to?(:status_resist) ? t.status_resist(:manuusa) : 0.0
      if rand > resist
        msg = StatusEffect.apply(t, :manuusa, spell_data['turns'] || 3)
        [msg || "#{t.name} の目がくらんだ！"]
      else
        ["しかし効果がなかった..."]
      end

    when 'silence'
      t = targets.first
      return ["対象がいない！"] unless t
      resist = t.respond_to?(:status_resist) ? t.status_resist(:mahotoon) : 0.0
      if rand > resist
        msg = StatusEffect.apply(t, :mahotoon, spell_data['turns'] || 3)
        [msg || "#{t.name} は呪文が封じられた！"]
      else
        ["しかし効果がなかった..."]
      end

    when 'warp'
      ["（ルーラはフィールドでのみ使える）"]

    when 'escape_dungeon'
      ["（リレミトはダンジョン内でのみ使える）"]

    else
      ["何も起きなかった..."]
    end
  end

  def self.damage_message(caster, target, spell_data, element)
    resist = element && target.respond_to?(:resist_rate) ? target.resist_rate(element) : 1.0
    return "#{target.name} には効果がなかった！" if resist == 0.0

    min_dmg = spell_data['min']
    max_dmg = spell_data['max']
    base    = rand(min_dmg..max_dmg)

    # Weapon spell bonus (e.g. magic rod)
    bonus_pct = caster.respond_to?(:inventory) ? caster.inventory.weapon_bonus('spell_bonus') : 0
    base = (base * (1.0 + bonus_pct / 100.0)).round

    dmg = (base * resist).round.clamp(1, 9999)
    target.take_damage(dmg)

    prefix = case resist
             when 1.5.. then "弱点をついた！ "
             when ..0.5 then "耐性がある... "
             else ""
             end
    "#{prefix}#{target.name} に #{dmg} のダメージ！"
  end
  private_class_method :damage_message
end
