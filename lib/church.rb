require_relative 'renderer'
require_relative 'save_data'
require_relative 'status_effect'

class Church
  STATUS_CLEAR_COST = 50

  def initialize(player)
    @player = player
  end

  def open
    loop do
      Renderer.clear
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "  [教会]  所持金: #{@player.gold}G"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      status_str = @player.status_summary
      puts "  状態: #{status_str.empty? ? '正常' : status_str}"
      puts ""
      puts "  1. おいのり（セーブ）"
      puts "  2. 状態異常を治す（#{STATUS_CLEAR_COST}G）"
      puts "  3. 出る"
      print "  > "

      case gets.chomp.strip
      when '1' then pray
      when '2' then clear_status
      when '3' then break
      end
    end
  end

  private

  def pray
    SaveData.save(@player)
    Renderer.clear
    puts ""
    puts "  神のご加護がありますように..."
    Renderer.wait(0.8)
    puts "  セーブしました。"
    Renderer.wait(1.5)
  end

  def clear_status
    if @player.status_effects.empty?
      puts "  状態異常にかかっていない。"
      Renderer.wait(1)
      return
    end

    if @player.gold < STATUS_CLEAR_COST
      puts "  お金が足りない！（#{STATUS_CLEAR_COST}G 必要）"
      Renderer.wait(1)
      return
    end

    @player.spend_gold(STATUS_CLEAR_COST)
    @player.status_effects.clear
    puts "  すべての状態異常が治った！"
    Renderer.wait(1.5)
  end
end
