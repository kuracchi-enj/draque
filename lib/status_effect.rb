module StatusEffect
  NAMES = {
    poison:    '毒',
    sleep:     '眠り',
    paralysis: '麻痺',
    confusion: '混乱',
    manuusa:   'マヌーサ',
    mahotoon:  'マホトーン'
  }.freeze

  POISON_DAMAGE = 5

  def self.name_of(effect)
    NAMES[effect] || effect.to_s
  end

  # Process ongoing status effects for one turn. Returns array of messages.
  def self.tick(entity)
    messages = []
    expired = []

    entity.status_effects.each do |effect, turns|
      case effect
      when :poison
        entity.take_damage(POISON_DAMAGE)
        messages << "#{entity.name} は毒の苦しみで #{POISON_DAMAGE} のダメージ！"
      end
      remaining = turns - 1
      remaining <= 0 ? expired << effect : entity.status_effects[effect] = remaining
    end

    expired.each { |e| entity.status_effects.delete(e) }
    messages
  end

  # Apply a status effect. Returns nil on success, message string if already afflicted.
  def self.apply(entity, effect, turns)
    return "すでに#{NAMES[effect]}状態だ" if entity.status_effects[effect].to_i > 0
    entity.status_effects[effect] = turns
    nil
  end

  def self.has?(entity, effect)
    entity.status_effects[effect].to_i > 0
  end

  # Wake from sleep with given probability. Returns true if woke up.
  def self.try_wake(entity)
    if rand < 0.33
      entity.status_effects.delete(:sleep)
      true
    else
      false
    end
  end

  # Clear non-persistent effects after battle ends (poison persists, rest do not).
  def self.clear_battle_effects(entity)
    [:sleep, :paralysis, :confusion, :manuusa, :mahotoon].each do |e|
      entity.status_effects.delete(e)
    end
  end
end
