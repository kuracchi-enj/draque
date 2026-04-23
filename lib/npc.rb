require 'json'
require_relative 'renderer'

class NPC
  DATA_PATH = File.join(__dir__, '..', 'data', 'npcs.json')

  def self.all
    @all ||= JSON.parse(File.read(DATA_PATH))
  end

  def self.talk(npc_id)
    data = all[npc_id]
    return unless data

    Renderer.clear
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "  #{data['name']}"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts ""
    data['lines'].each { |line| puts "  「#{line}」" }
    puts ""
    puts "  （Enterで閉じる）"
    gets
  end
end
