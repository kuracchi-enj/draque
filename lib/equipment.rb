require 'json'

class Weapon
  DATA_PATH = File.join(__dir__, '..', 'data', 'weapons.json')

  attr_reader :id, :name, :type, :atk_bonus, :agi_bonus, :spell_bonus, :heal_bonus,
              :buy, :sell, :allowed_jobs

  def self.all
    @all ||= JSON.parse(File.read(DATA_PATH)).map { |d| new(d) }
  end

  def self.find(id)
    all.find { |w| w.id == id } || raise("未知の武器ID: #{id}")
  end

  def initialize(data)
    @id          = data['id']
    @name        = data['name']
    @type        = data['type']
    @atk_bonus   = data['atk_bonus']
    @agi_bonus   = data['agi_bonus']
    @spell_bonus = data['spell_bonus']
    @heal_bonus  = data['heal_bonus']
    @buy         = data['buy']
    @sell        = data['sell']
    @allowed_jobs = data['allowed_jobs']
  end

  def equippable_by?(job_name)
    @allowed_jobs.include?(job_name)
  end
end

class Armor
  DATA_PATH = File.join(__dir__, '..', 'data', 'armors.json')

  attr_reader :id, :name, :slot, :armor_type, :def_bonus, :buy, :sell, :allowed_jobs

  def self.all
    @all ||= JSON.parse(File.read(DATA_PATH)).values.flatten.map { |d| new(d) }
  end

  def self.find(id)
    all.find { |a| a.id == id } || raise("未知の防具ID: #{id}")
  end

  def initialize(data)
    @id          = data['id']
    @name        = data['name']
    @slot        = data['slot']
    @armor_type  = data['armor_type']
    @def_bonus   = data['def_bonus']
    @buy         = data['buy']
    @sell        = data['sell']
    @allowed_jobs = data['allowed_jobs']
  end

  def equippable_by?(job_name)
    @allowed_jobs.include?(job_name)
  end
end
