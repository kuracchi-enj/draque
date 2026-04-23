require_relative 'renderer'
require_relative 'player'
require_relative 'save_data'
require_relative 'map'

class Game
  JOBS = %w[剣士 僧侶 魔法使い 忍者 重戦士].freeze

  def start
    Renderer.clear
    Renderer.title_banner
    puts "  1. はじめから"
    puts "  2. つづきから"
    puts "  3. 終了"
    print "  > "

    case gets.chomp.strip.downcase
    when '1', 'new'                     then new_game
    when '2', 'load', 'require'         then load_game
    when '3', 'exit', 'quit'            then puts "  またね！"; exit
    else start
    end
  end

  private

  def new_game
    Renderer.clear
    Renderer.title_banner
    puts "  あなたの名前を入力してください："
    print "  > "
    name = gets.chomp.strip
    name = '勇者' if name.empty?

    job_name = select_job

    player = Player.new(name: name, job_name: job_name)
    puts ""
    puts "  #{player.name}（#{job_name}）の冒険が始まった！"
    Renderer.wait(2)

    run_game(player)
  end

  def select_job
    loop do
      Renderer.clear
      Renderer.title_banner
      puts "  職業を選んでください："
      puts ""
      JOBS.each_with_index do |job, i|
        require_relative 'job'
        desc = Job[job].description
        puts "  #{i + 1}. #{job}  ─  #{desc}"
      end
      puts ""
      print "  > "
      idx = gets.chomp.to_i
      return JOBS[idx - 1] if idx.between?(1, JOBS.size)
      puts "  正しい番号を入力してください。"
      Renderer.wait(1)
    end
  end

  def load_game
    slots = SaveData.slots
    if slots.empty?
      puts "  セーブデータがありません。"
      Renderer.wait(1.5)
      start
      return
    end

    Renderer.clear
    puts "  ── セーブデータを選んでください ──"
    puts ""
    slots.each do |s|
      d = s[:data]
      puts "  スロット#{s[:slot]}: #{d['name']}（#{d['job_name']}）Lv#{d['level']}  エリア#{d['current_area']}"
    end
    puts "  0. もどる"
    print "  > "
    idx = gets.chomp.to_i
    if idx == 0
      start
      return
    end

    slot_info = slots.find { |s| s[:slot] == idx }
    unless slot_info
      puts "  そのスロットは存在しない。"
      Renderer.wait(1)
      load_game
      return
    end

    player = SaveData.load(slot: idx)
    puts "  データを読み込んだ！"
    Renderer.wait(1)
    run_game(player)
  end

  def run_game(player)
    result = Map.new(player).run

    case result
    when :cleared
      ending(player)
    when :dead
      game_over(player)
    end
  end

  def ending(player)
    Renderer.clear
    puts ""
    puts "  ★★★★★★★★★★★★★★★★★★★★"
    puts "  ★                          ★"
    puts "  ★   魔王バルドラスを倒した！  ★"
    puts "  ★                          ★"
    puts "  ★   #{player.name}は伝説の勇者    ★"
    puts "  ★   として歴史に名を刻んだ。  ★"
    puts "  ★                          ★"
    puts "  ★★★★★★★★★★★★★★★★★★★★"
    puts ""
    puts "  おめでとうございます！ THE END"
    puts ""
  end

  def game_over(player)
    Renderer.clear
    puts ""
    puts "  ┌──────────────────────┐"
    puts "  │       GAME  OVER     │"
    puts "  └──────────────────────┘"
    puts ""
    puts "  #{player.name}の冒険は、ここで幕を閉じた…"
    puts ""

    revival_cost = player.gold / 2
    if revival_cost > 0
      puts "  教会で復活しますか？（所持金の半額 #{revival_cost}G）(y/n)"
      print "  > "
      answer = gets.chomp.strip.downcase
      if %w[y yes retry].include?(answer)
        player.spend_gold(revival_cost)
        player.hp = [player.max_hp / 4, 1].max
        player.status_effects.clear
        puts "  教会で目を覚ました…"
        Renderer.wait(2)
        run_game(player)
        return
      end
    end

    puts "  Enterでタイトルに戻る"
    gets
    start
  end
end
