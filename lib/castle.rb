require_relative 'renderer'

class Castle
  REWARDS = {
    after_A: 200,
    after_B: 500
  }.freeze

  def initialize(player)
    @player = player
  end

  def enter
    Renderer.clear
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "  [はじまりの城 ─ 王の間]"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts ""

    defeated = @player.defeated_bosses

    if defeated.include?('C')
      speech_victory
    elsif defeated.include?('B')
      speech_after_b
    elsif defeated.include?('A')
      speech_after_a
    else
      speech_intro
    end

    puts ""
    puts "  （Enterで退出）"
    gets
  end

  private

  def speech_intro
    puts "  王様: 「よく来た、#{@player.name}よ。」"
    puts ""
    puts "  王様: 「魔王バルドラスが世界に混乱をもたらしている。」"
    puts "  王様: 「伝説の勇者の血を引くそなたに頼みたい。」"
    puts "  王様: 「まず北の草原のゴブリンキングを討伐せよ。」"
    puts "  王様: 「それが世界を救う第一歩になるじゃろう。」"
    puts ""
    puts "  王様: 「勇者の武運を祈る！」"
  end

  def speech_after_a
    puts "  王様: 「見事じゃ！ゴブリンキングを倒したとは。」"
    puts ""
    puts "  王様: 「森の奥地にはさらに強い魔物がいるそうじゃ。」"
    puts "  王様: 「ドラゴンを倒して先の道を切り開け！」"
    puts ""

    reward = REWARDS[:after_A]
    @player.gain_gold(reward)
    puts "  王様より #{reward}G を受け取った！"
  end

  def speech_after_b
    puts "  王様: 「ドラゴンまでも討ち果たしたか……！」"
    puts ""
    puts "  王様: 「魔王城への道はもう目の前じゃ。」"
    puts "  王様: 「最果ての街で準備を整え、魔王に挑め！」"
    puts "  王様: 「世界の命運はそなたの肩にかかっておる。」"
    puts ""

    reward = REWARDS[:after_B]
    @player.gain_gold(reward)
    puts "  王様より #{reward}G を受け取った！"
  end

  def speech_victory
    puts "  王様: 「魔王バルドラスを倒したとは……！」"
    puts ""
    puts "  王様: 「そなたの名は永遠に語り継がれるであろう。」"
    puts "  王様: 「真の英雄よ、心よりの感謝を。」"
  end
end
