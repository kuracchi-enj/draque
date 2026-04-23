require_relative 'renderer'
require_relative 'item'
require_relative 'equipment'

class Shop
  def initialize(player, area_data)
    @player    = player
    @area_data = area_data
  end

  # Combined shop (used from legacy enter_town flow if needed)
  def open
    loop do
      Renderer.clear
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "  ようこそ！何をお探しですか？"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "  所持金: #{@player.gold}G"
      puts ""
      puts "  1. 武器を買う"
      puts "  2. 防具を買う"
      puts "  3. アイテムを買う"
      puts "  4. アイテムを売る"
      puts "  5. 装備を外す"
      puts "  6. 出る"
      print "  > "

      case gets.chomp.strip
      when '1' then buy_weapons
      when '2' then buy_armors
      when '3' then buy_items
      when '4' then sell_items
      when '5' then unequip_menu
      when '6' then break
      end
    end
  end

  # Separate facility entrances called from Town
  def open_weapons
    loop do
      Renderer.clear
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "  [武器屋]  所持金: #{@player.gold}G"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "  1. 武器を買う"
      puts "  2. 装備を外す"
      puts "  3. 出る"
      print "  > "
      case gets.chomp.strip.downcase
      when '1' then buy_weapons
      when '2' then unequip_menu
      when '3', 'exit', 'quit' then break
      end
    end
  end

  def open_armors
    loop do
      Renderer.clear
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "  [防具屋]  所持金: #{@player.gold}G"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "  1. 防具を買う"
      puts "  2. 装備を外す"
      puts "  3. 出る"
      print "  > "
      case gets.chomp.strip.downcase
      when '1' then buy_armors
      when '2' then unequip_menu
      when '3', 'exit', 'quit' then break
      end
    end
  end

  def open_items
    loop do
      Renderer.clear
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "  [道具屋]  所持金: #{@player.gold}G"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "  1. アイテムを買う"
      puts "  2. アイテムを売る"
      puts "  3. 出る"
      print "  > "
      case gets.chomp.strip.downcase
      when '1' then buy_items
      when '2' then sell_items
      when '3', 'exit', 'quit' then break
      end
    end
  end

  private

  def buy_weapons
    ids = @area_data['shop']['weapons']
    weapons = ids.map { |id| Weapon.find(id) }
    loop do
      Renderer.clear
      puts "  ── 武器屋 ──  所持金: #{@player.gold}G"
      puts ""
      weapons.each_with_index do |w, i|
        can = w.equippable_by?(@player.job_name) ? '' : ' [装備不可]'
        puts "  #{i + 1}. #{w.name}  攻+#{w.atk_bonus}#{w.agi_bonus > 0 ? " 素+#{w.agi_bonus}" : ''}  #{w.buy}G#{can}"
      end
      puts "  0. もどる"
      print "  > "
      idx = gets.chomp.to_i
      break if idx == 0 || idx > weapons.size

      w = weapons[idx - 1]
      unless w.equippable_by?(@player.job_name)
        puts "  その職業は装備できない！"
        Renderer.wait(1)
        next
      end
      if @player.gold < w.buy
        puts "  お金が足りない！"
        Renderer.wait(1)
        next
      end
      @player.spend_gold(w.buy)
      @player.inventory.equip_weapon(w)
      puts "  「#{w.name}」を買って装備した！"
      Renderer.wait(1)
    end
  end

  def buy_armors
    ids = @area_data['shop']['armors']
    armors = ids.map { |id| Armor.find(id) }
    loop do
      Renderer.clear
      puts "  ── 防具屋 ──  所持金: #{@player.gold}G"
      puts ""
      armors.each_with_index do |a, i|
        slot_label = { 'head' => '頭', 'body' => '上半身', 'legs' => '下半身' }[a.slot]
        can = a.equippable_by?(@player.job_name) ? '' : ' [装備不可]'
        puts "  #{i + 1}. [#{slot_label}]#{a.name}  防+#{a.def_bonus}  #{a.buy}G#{can}"
      end
      puts "  0. もどる"
      print "  > "
      idx = gets.chomp.to_i
      break if idx == 0 || idx > armors.size

      a = armors[idx - 1]
      unless a.equippable_by?(@player.job_name)
        puts "  その職業は装備できない！"
        Renderer.wait(1)
        next
      end
      if @player.gold < a.buy
        puts "  お金が足りない！"
        Renderer.wait(1)
        next
      end
      @player.spend_gold(a.buy)
      @player.inventory.equip_armor(a)
      puts "  「#{a.name}」を買って装備した！"
      Renderer.wait(1)
    end
  end

  def buy_items
    ids = @area_data['shop']['items']
    items = ids.map { |id| Item.find(id) }
    loop do
      Renderer.clear
      puts "  ── 道具屋 ──  所持金: #{@player.gold}G"
      puts ""
      items.each_with_index do |it, i|
        puts "  #{i + 1}. #{it.name}  #{it.buy}G"
      end
      puts "  0. もどる"
      print "  > "
      idx = gets.chomp.to_i
      break if idx == 0 || idx > items.size

      it = items[idx - 1]
      if @player.gold < it.buy
        puts "  お金が足りない！"
        Renderer.wait(1)
        next
      end
      if @player.inventory.add_item(it.id)
        @player.spend_gold(it.buy)
        puts "  「#{it.name}」を買った！"
      else
        puts "  これ以上持てない！"
      end
      Renderer.wait(1)
    end
  end

  def sell_items
    loop do
      Renderer.clear
      puts "  ── 売る ──  所持金: #{@player.gold}G"
      puts ""
      item_list = @player.inventory.item_list
      if item_list.empty?
        puts "  売るものがない。"
        Renderer.wait(1)
        break
      end
      item_list.each_with_index do |(it, cnt), i|
        puts "  #{i + 1}. #{it.name} x#{cnt}  (売値 #{it.sell}G)"
      end
      puts "  0. もどる"
      print "  > "
      idx = gets.chomp.to_i
      break if idx == 0 || idx > item_list.size

      it, = item_list[idx - 1]
      @player.inventory.remove_item(it.id)
      @player.gain_gold(it.sell)
      puts "  「#{it.name}」を #{it.sell}G で売った！"
      Renderer.wait(1)
    end
  end

  def unequip_menu
    Renderer.clear
    puts "  ── 装備を外す ──"
    puts ""
    inv = @player.inventory
    slots = [
      ['武器', inv.weapon],
      ['頭', inv.head],
      ['上半身', inv.body],
      ['下半身', inv.legs]
    ]
    slots.each_with_index do |(label, eq), i|
      puts "  #{i + 1}. [#{label}] #{eq ? eq.name : '(なし)'}"
    end
    puts "  0. もどる"
    print "  > "
    idx = gets.chomp.to_i
    case idx
    when 1 then inv.weapon = nil; puts "  武器を外した。"
    when 2 then inv.head   = nil; puts "  頭の防具を外した。"
    when 3 then inv.body   = nil; puts "  上半身の防具を外した。"
    when 4 then inv.legs   = nil; puts "  下半身の防具を外した。"
    end
    Renderer.wait(1) if idx.between?(1, 4)
  end
end
