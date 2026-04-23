require 'json'

class Item
  DATA_PATH = File.join(__dir__, '..', 'data', 'items.json')

  attr_reader :id, :name, :type, :amount, :buy, :sell

  def self.all
    @all ||= JSON.parse(File.read(DATA_PATH)).map { |d| new(d) }
  end

  def self.find(id)
    all.find { |i| i.id == id } || raise("未知のアイテムID: #{id}")
  end

  def initialize(data)
    @id     = data['id']
    @name   = data['name']
    @type   = data['type']
    @amount = data['amount']
    @buy    = data['buy']
    @sell   = data['sell']
  end

  def use(player)
    case @type
    when 'heal_hp'
      healed = [player.max_hp - player.hp, @amount].min
      player.heal_hp(@amount)
      "#{player.name}のHPが #{healed} 回復した！"
    when 'heal_mp'
      healed = [player.max_mp - player.mp, @amount].min
      player.heal_mp(@amount)
      "#{player.name}のMPが #{healed} 回復した！"
    when 'buff_atk'
      player.atk_buff += @amount
      "#{player.name}の攻撃力が #{@amount} 上がった！"
    when 'buff_def'
      player.def_buff += @amount
      "#{player.name}の防御力が #{@amount} 上がった！"
    else
      '効果がなかった...'
    end
  end
end
