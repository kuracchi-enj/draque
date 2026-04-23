require 'json'

module SaveData
  SAVE_DIR = File.join(__dir__, '..', 'data', 'saves')

  def self.save(player, slot: 1)
    FileUtils.mkdir_p(SAVE_DIR)
    path    = File.join(SAVE_DIR, "slot_#{slot}.json")
    tmp     = path + '.tmp'
    File.write(tmp, JSON.pretty_generate(player.to_h))
    File.rename(tmp, path)
  end

  def self.slots
    Dir.glob(File.join(SAVE_DIR, 'slot_*.json')).sort.map do |path|
      slot = File.basename(path, '.json').sub('slot_', '').to_i
      data = JSON.parse(File.read(path))
      { slot: slot, path: path, data: data }
    end
  end

  def self.load(slot: 1)
    require_relative 'player'
    path = File.join(SAVE_DIR, "slot_#{slot}.json")
    raise "スロット#{slot}のデータが見つからない" unless File.exist?(path)
    Player.from_h(JSON.parse(File.read(path)))
  end
end
