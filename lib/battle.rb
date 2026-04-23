require_relative 'renderer'
require_relative 'item'
require_relative 'equipment'
require_relative 'spell'
require_relative 'status_effect'

class Battle
  CRITICAL_RATE = 1.0 / 32
  PAIN_RATE     = 1.0 / 64
  HIT_RATE      = 0.95
  MAX_LOG_LINES = 10

  def initialize(player, monsters, is_boss: false)
    @player   = player
    @monsters = monsters.is_a?(Array) ? monsters : [monsters]
    @is_boss  = is_boss
    @guarding = false
    @log      = []
  end

  def run
    announce_appearance
    redraw
    Renderer.wait(1)
    @player.reset_buffs

    loop do
      @guarding = false

      process_status_ticks(@player)
      return :dead unless @player.alive?

      redraw

      result = player_turn
      return result if result == :escaped
      return :won  if finish_if_won

      Renderer.wait(0.4)

      alive_monsters.sort_by { |m| -(m.agi + rand(m.agi / 2 + 1)) }.each do |monster|
        next unless monster.alive?

        process_status_ticks(monster)

        unless monster.alive?
          log("#{monster.name} は毒で力尽きた！")
          redraw
          Renderer.wait(0.5)
          next
        end

        if try_skip_due_to_status(monster)
          redraw
          Renderer.wait(0.3)
          next
        end

        result = monster_turn(monster)
        return :dead if result == :dead
        redraw
        Renderer.wait(0.4)
      end

      return :won if finish_if_won
    end
  end

  private

  # ────────────────────────────────────────
  # Log & redraw
  # ────────────────────────────────────────

  def log(msg)
    @log << msg
    @log.shift while @log.size > MAX_LOG_LINES
  end

  def redraw
    Renderer.clear
    display_status
    display_log
  end

  def display_log
    return if @log.empty?
    puts "  ── 行動ログ ──"
    @log.each { |m| puts "  #{m}" }
    puts ""
  end

  # ────────────────────────────────────────
  # Display
  # ────────────────────────────────────────

  def announce_appearance
    if @monsters.size > 1
      groups = @monsters.group_by(&:name)
                        .map { |name, ms| ms.size > 1 ? "#{name}×#{ms.size}" : name }
      log("#{groups.join('、')} たちが現れた！")
    else
      label = @is_boss ? '【ボス】' : ''
      log("#{label}#{@monsters.first.name} が現れた！")
    end
  end

  def display_status
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @monsters.each_with_index do |m, i|
      if m.alive?
        s = m.status_summary
        puts "  #{i + 1}. #{m.name}  HP: #{m.hp}/#{m.max_hp}#{s.empty? ? '' : "  [#{s}]"}"
      else
        puts "  #{i + 1}. #{m.name}  [倒れた]"
      end
    end
    puts ""
    ps = @player.status_summary
    puts "  #{@player.name} (Lv#{@player.level})  HP: #{@player.hp}/#{@player.max_hp}  MP: #{@player.mp}/#{@player.max_mp}#{ps.empty? ? '' : "  [#{ps}]"}"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts ""
  end

  # ────────────────────────────────────────
  # Status helpers
  # ────────────────────────────────────────

  def process_status_ticks(entity)
    StatusEffect.tick(entity).each { |m| log(m) }
  end

  def try_skip_due_to_status(entity)
    if StatusEffect.has?(entity, :sleep)
      if StatusEffect.try_wake(entity)
        log("#{entity.name} は目を覚ました！")
      else
        log("#{entity.name} は眠っている...")
        return true
      end
    end

    if StatusEffect.has?(entity, :paralysis) && rand < 0.5
      log("#{entity.name} は麻痺して動けない！")
      return true
    end

    false
  end

  def alive_monsters
    @monsters.select(&:alive?)
  end

  def won?
    @monsters.none?(&:alive?)
  end

  def finish_if_won
    return false unless won?
    show_victory
    true
  end

  # ────────────────────────────────────────
  # Victory
  # ────────────────────────────────────────

  def show_victory
    @monsters.each { |m| log("★ #{m.name} を倒した！") }

    total_exp  = @monsters.sum(&:exp)
    total_gold = @monsters.sum(&:gold)
    level_msgs = @player.gain_exp(total_exp)
    @player.gain_gold(total_gold)

    log("経験値 #{total_exp} を手に入れた！") if total_exp > 0
    log("ゴールド #{total_gold}G を手に入れた！") if total_gold > 0
    level_msgs.each { |m| log("★ #{m}") }

    redraw
    Renderer.wait(1.5)

    handle_all_drops unless @is_boss

    StatusEffect.clear_battle_effects(@player)
  end

  def handle_all_drops
    @monsters.each { |m| handle_drops(m) }
  end

  def handle_drops(monster)
    monster.roll_drops.each do |drop|
      item_name = case drop['item_type']
                  when 'item'   then Item.find(drop['item_id']).name
                  when 'weapon' then Weapon.find(drop['item_id']).name
                  when 'armor'  then Armor.find(drop['item_id']).name
                  end

      case drop['item_type']
      when 'item'
        if @player.inventory.add_item(drop['item_id'])
          log("「#{item_name}」を手に入れた！")
        else
          log("「#{item_name}」を持ちきれなかった...")
        end
        redraw
        Renderer.wait(0.8)
      when 'weapon'
        w = Weapon.find(drop['item_id'])
        if w.equippable_by?(@player.job_name)
          log("「#{item_name}」を手に入れた！")
          redraw
          print "  装備しますか？(y/n) > "
          @player.inventory.equip_weapon(w) if gets.chomp.downcase == 'y'
        end
      when 'armor'
        a = Armor.find(drop['item_id'])
        if a.equippable_by?(@player.job_name)
          log("「#{item_name}」を手に入れた！")
          redraw
          print "  装備しますか？(y/n) > "
          @player.inventory.equip_armor(a) if gets.chomp.downcase == 'y'
        end
      end
    end
  end

  # ────────────────────────────────────────
  # Player turn
  # ────────────────────────────────────────

  def player_turn
    if try_skip_due_to_status(@player)
      redraw
      Renderer.wait(0.5)
      return nil
    end

    can_spell = @player.job.can_cast &&
                @player.learned_spells.any? &&
                !StatusEffect.has?(@player, :mahotoon)

    puts "  コマンド："
    puts "  1. たたかう"
    puts "  2. じゅもん" if can_spell
    puts "  3. どうぐ"
    puts "  4. ぼうぎょ"
    puts "  5. にげる" unless @is_boss
    print "  > "

    case gets.chomp.strip
    when '1' then player_attack
    when '2'
      if can_spell
        player_spell
      elsif StatusEffect.has?(@player, :mahotoon)
        log("呪文が封じられている！"); redraw; Renderer.wait(0.8); nil
      else
        log("呪文は使えない！"); redraw; Renderer.wait(0.8); nil
      end
    when '3' then player_item
    when '4' then player_guard
    when '5'
      if @is_boss
        log("ボスからは逃げられない！"); redraw; Renderer.wait(0.8); nil
      else
        player_escape
      end
    else
      nil
    end
  end

  def select_target
    alive = alive_monsters
    return alive.first if alive.size == 1

    puts "  誰を攻撃しますか？"
    alive.each_with_index do |m, i|
      puts "  #{i + 1}. #{m.name} (HP:#{m.hp}/#{m.max_hp})"
    end
    print "  > "
    idx = gets.chomp.to_i
    idx = 1 unless idx.between?(1, alive.size)
    alive[idx - 1]
  end

  def player_attack
    target = select_target
    return nil unless target

    hit_rate = StatusEffect.has?(@player, :manuusa) ? 0.25 : HIT_RATE
    unless rand < hit_rate
      log("#{@player.name} の攻撃は外れた！")
      redraw
      Renderer.wait(0.5)
      return nil
    end

    if rand < CRITICAL_RATE
      damage = @player.total_attack * 2
      log("会心の一撃！！")
    else
      damage = calc_damage(@player.total_attack, target.def)
    end

    target.take_damage(damage)
    log("#{@player.name} の攻撃！ #{target.name} に #{damage} のダメージ！")
    log("#{target.name} を倒した！") unless target.alive?
    redraw
    Renderer.wait(0.5)
    nil
  end

  def player_guard
    @guarding = true
    log("#{@player.name} はぼうぎょした！")
    redraw
    Renderer.wait(0.4)
    nil
  end

  def player_spell
    spells = @player.learned_spells
    puts ""
    puts "  呪文を選んでください："
    spells.each_with_index do |s, i|
      puts "  #{i + 1}. #{s['name']} (MP:#{s['mp']}) - #{s['desc']}"
    end
    puts "  0. もどる"
    print "  > "
    idx = gets.chomp.to_i
    return nil if idx == 0 || idx > spells.size

    spell = spells[idx - 1]
    if @player.mp < spell['mp']
      log("MPが足りない！")
      redraw
      Renderer.wait(0.8)
      return nil
    end

    @player.use_mp(spell['mp'])
    log("#{@player.name} は #{spell['name']} を唱えた！")

    targets = case spell['effect']
              when 'damage_all'
                alive_monsters
              when 'heal_hp', 'heal_hp_full', 'buff_atk', 'buff_def', 'warp', 'escape_dungeon'
                []
              else
                t = select_target
                t ? [t] : []
              end

    alive_before = @monsters.select(&:alive?).map(&:object_id)
    msgs = Spell.cast(@player, spell, targets: targets, self_target: @player)
    msgs.each { |m| log(m) }

    unless won?
      @monsters.each do |m|
        log("#{m.name} を倒した！") if alive_before.include?(m.object_id) && !m.alive?
      end
    end

    redraw
    Renderer.wait(1)
    nil
  end

  def player_item
    items = @player.inventory.item_list
    if items.empty?
      log("アイテムを持っていない！")
      redraw
      Renderer.wait(0.8)
      return nil
    end
    puts ""
    puts "  使うアイテムを選んでください："
    items.each_with_index do |(item, cnt), i|
      puts "  #{i + 1}. #{item.name} x#{cnt}"
    end
    puts "  0. もどる"
    print "  > "
    idx = gets.chomp.to_i
    return nil if idx == 0 || idx > items.size

    item, = items[idx - 1]
    @player.inventory.remove_item(item.id)
    msg = item.use(@player)
    log(msg)
    redraw
    Renderer.wait(0.8)
    nil
  end

  def player_escape
    max_agi = alive_monsters.map(&:agi).max.to_f
    rate = @player.total_agility / (@player.total_agility + max_agi + 1)
    if rand < rate
      log("うまく逃げ出した！")
      redraw
      Renderer.wait(1)
      StatusEffect.clear_battle_effects(@player)
      :escaped
    else
      log("しかし逃げられなかった！")
      redraw
      Renderer.wait(0.8)
      nil
    end
  end

  # ────────────────────────────────────────
  # Monster turn
  # ────────────────────────────────────────

  def monster_turn(monster)
    usable_spells = monster.spells.select { |s| monster.mp >= s['mp'] }

    if usable_spells.any? && rand < 0.30 && !StatusEffect.has?(monster, :mahotoon)
      monster_spell_turn(monster, usable_spells)
    else
      monster_attack(monster)
    end
  end

  def monster_attack(monster)
    hit_rate = StatusEffect.has?(monster, :manuusa) ? 0.25 : 0.95
    unless rand < hit_rate
      log("#{monster.name} の攻撃は外れた！")
      return nil
    end

    if rand < PAIN_RATE
      damage = monster.atk * 2
      log("#{monster.name} の痛恨の一撃！！")
    else
      defense = @guarding ? @player.total_defense * 2 : @player.total_defense
      damage  = calc_damage(monster.atk, defense)
    end

    @player.take_damage(damage)
    log("#{monster.name} の攻撃！ #{@player.name} に #{damage} のダメージ！")

    if monster.status_attacks.any? && rand < 0.20
      status = monster.status_attacks.sample
      msg = StatusEffect.apply(@player, status, 3)
      unless msg
        log("#{@player.name} は#{StatusEffect::NAMES[status] || status}になった！")
      end
    end

    unless @player.alive?
      log("★ #{@player.name} は倒れてしまった…")
      redraw
      Renderer.wait(1.5)
      return :dead
    end
    nil
  end

  def monster_spell_turn(monster, usable_spells)
    spell = usable_spells.sample
    monster.use_mp(spell['mp'])
    log("#{monster.name} は #{spell['name']} を唱えた！")

    msgs = Spell.cast(monster, spell, targets: [@player], self_target: @player)
    msgs.each { |m| log(m) }

    unless @player.alive?
      log("★ #{@player.name} は倒れてしまった…")
      redraw
      Renderer.wait(1.5)
      return :dead
    end
    nil
  end

  # ────────────────────────────────────────
  # Damage formula
  # ────────────────────────────────────────

  def calc_damage(attack, defense)
    base = attack - defense / 2
    dmg  = base + rand(-2..2)
    [dmg, 1].max
  end
end
