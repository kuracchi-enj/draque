require_relative 'item'
require_relative 'equipment'

module Treasure
  CHEST_COUNT = 3

  # Weighted loot tables per area.
  # :kind one of 'item' / 'weapon' / 'armor' / 'gold'
  LOOT_TABLES = {
    'A' => [
      { weight: 3, kind: 'item',   id: 'yakusou' },
      { weight: 2, kind: 'item',   id: 'mahou_seisui' },
      { weight: 2, kind: 'gold',   min:  30, max: 100 },
      { weight: 1, kind: 'weapon', id: 'dou_sword' }
    ],
    'B' => [
      { weight: 3, kind: 'item',   id: 'jou_yakusou' },
      { weight: 2, kind: 'item',   id: 'mahou_seisui' },
      { weight: 2, kind: 'item',   id: 'kidzuke_gusuri' },
      { weight: 2, kind: 'gold',   min: 100, max: 300 },
      { weight: 1, kind: 'weapon', id: 'iron_sword' },
      { weight: 1, kind: 'armor',  id: 'chain_mail' }
    ],
    'C' => [
      { weight: 3, kind: 'item',   id: 'whey_protein' },
      { weight: 2, kind: 'item',   id: 'kidzuke_gusuri' },
      { weight: 2, kind: 'gold',   min: 200, max: 500 },
      { weight: 1, kind: 'weapon', id: 'steel_sword' },
      { weight: 1, kind: 'armor',  id: 'royal_armor' }
    ]
  }.freeze

  # Place CHEST_COUNT chests at random '.' tiles, avoiding key positions.
  def self.generate_for_area(area)
    reserved = [area.player_start, area.town_pos, area.boss_pos]
    candidates = []
    area.height.times do |y|
      area.width.times do |x|
        next unless area.tile_at(x, y) == '.'
        next if reserved.include?([x, y])
        candidates << [x, y]
      end
    end

    n = [CHEST_COUNT, candidates.size].min
    candidates.sample(n).map do |pos|
      { 'pos' => pos, 'loot' => sample_loot(area.key), 'opened' => false }
    end
  end

  def self.sample_loot(area_key)
    table = LOOT_TABLES[area_key] || []
    return { 'kind' => 'item', 'id' => 'yakusou' } if table.empty?

    total = table.sum { |e| e[:weight] }
    roll  = rand(total)
    cum   = 0
    chosen = table.find { |e| cum += e[:weight]; roll < cum }

    case chosen[:kind]
    when 'gold'
      { 'kind' => 'gold', 'amount' => rand(chosen[:min]..chosen[:max]) }
    else
      { 'kind' => chosen[:kind], 'id' => chosen[:id] }
    end
  end

  # Open a chest; returns a message string describing the outcome.
  def self.open(player, treasure)
    return nil if treasure['opened']
    treasure['opened'] = true
    loot = treasure['loot']

    case loot['kind']
    when 'gold'
      player.gain_gold(loot['amount'])
      "#{loot['amount']}G を手に入れた！"
    when 'item'
      item = Item.find(loot['id'])
      if player.inventory.add_item(item.id)
        "「#{item.name}」を手に入れた！"
      else
        "「#{item.name}」が入っていたが、持ちきれなかった..."
      end
    when 'weapon'
      w = Weapon.find(loot['id'])
      if w.equippable_by?(player.job_name)
        player.inventory.equip_weapon(w)
        "「#{w.name}」を手に入れて装備した！"
      else
        "「#{w.name}」を手に入れたが、装備できない..."
      end
    when 'armor'
      a = Armor.find(loot['id'])
      if a.equippable_by?(player.job_name)
        player.inventory.equip_armor(a)
        "「#{a.name}」を手に入れて装備した！"
      else
        "「#{a.name}」を手に入れたが、装備できない..."
      end
    else
      "何もない..."
    end
  end
end
