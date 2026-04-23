require_relative 'item'
require_relative 'equipment'

class Inventory
  MAX_ITEMS = 16

  attr_accessor :items, :weapon, :head, :body, :legs

  def initialize
    @items  = {}   # { item_id => count }
    @weapon = nil  # Weapon instance
    @head   = nil  # Armor instance
    @body   = nil  # Armor instance
    @legs   = nil  # Armor instance
  end

  def add_item(item_id, count = 1)
    return false if total_item_count >= MAX_ITEMS && !@items.key?(item_id)
    @items[item_id] = (@items[item_id] || 0) + count
    true
  end

  def remove_item(item_id, count = 1)
    return false unless @items[item_id] && @items[item_id] >= count
    @items[item_id] -= count
    @items.delete(item_id) if @items[item_id] == 0
    true
  end

  def total_item_count
    @items.values.sum
  end

  def item_list
    @items.map { |id, cnt| [Item.find(id), cnt] }
  end

  def equip_weapon(weapon)
    @weapon = weapon
  end

  def equip_armor(armor)
    case armor.slot
    when 'head' then @head = armor
    when 'body' then @body = armor
    when 'legs' then @legs = armor
    end
  end

  def weapon_bonus(stat)
    @weapon ? (@weapon.send(stat) || 0) : 0
  end

  def armor_bonus(stat)
    [@head, @body, @legs].compact.sum { |a| a.respond_to?(stat) ? a.send(stat) : 0 }
  end

  def equipped_armors
    [@head, @body, @legs].compact
  end

  def to_h
    {
      'items'  => @items,
      'weapon' => @weapon&.id,
      'head'   => @head&.id,
      'body'   => @body&.id,
      'legs'   => @legs&.id
    }
  end

  def self.from_h(h)
    inv = new
    inv.items  = h['items'] || {}
    inv.weapon = h['weapon'] ? Weapon.find(h['weapon']) : nil
    inv.head   = h['head']   ? Armor.find(h['head'])   : nil
    inv.body   = h['body']   ? Armor.find(h['body'])   : nil
    inv.legs   = h['legs']   ? Armor.find(h['legs'])   : nil
    inv
  end
end
