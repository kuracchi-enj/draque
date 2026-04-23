require_relative 'renderer'
require_relative 'save_data'

class Inn
  def initialize(player, area_data)
    @player    = player
    @area_data = area_data
  end

  def open
    loop do
      Renderer.clear
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "  ☆ 宿屋 ☆  (所持金: #{@player.gold}G)"
      puts "  HP: #{@player.hp}/#{@player.max_hp}  MP: #{@player.mp}/#{@player.max_mp}"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      courses = @area_data['inn']['courses']
      courses.each_with_index do |c, i|
        hp_txt = c['hp_rate'] == 1.0 ? 'HP全回復' : "HP#{(c['hp_rate'] * 100).to_i}%回復"
        mp_txt = c['mp_rate'] == 1.0 ? '+MP全回復' : (c['mp_rate'] > 0 ? "+MP#{(c['mp_rate'] * 100).to_i}%回復" : '')
        puts "  #{i + 1}. #{c['name']}  #{c['gold']}G  [#{hp_txt}#{mp_txt}]"
      end
      puts "  S. セーブする"
      puts "  0. 出る"
      print "  > "

      input = gets.chomp.strip.downcase
      case input
      when '0', 'exit', 'quit'
        break
      when 's', 'save', 'dump'
        save_game
      else
        stay(courses[input.to_i - 1]) if input.to_i.between?(1, courses.size)
      end
    end
  end

  private

  def stay(course)
    if @player.gold < course['gold']
      puts "  お金が足りない！"
      Renderer.wait(1)
      return
    end
    @player.spend_gold(course['gold'])
    heal_hp   = [(@player.max_hp  * course['hp_rate']).round, @player.max_hp].min
    heal_mp   = [(@player.max_mp  * course['mp_rate']).round, @player.max_mp].min
    @player.hp = [heal_hp, @player.max_hp].min
    @player.mp = [heal_mp, @player.max_mp].min
    puts ""
    puts "  ぐっすり眠った..."
    Renderer.wait(1)
    puts "  HP と MP が回復した！"
    Renderer.wait(1.5)
  end

  def save_game
    SaveData.save(@player)
    puts "  セーブした！"
    Renderer.wait(1.5)
  end
end
