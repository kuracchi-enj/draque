require 'io/console'
require_relative 'renderer'
require_relative 'area'
require_relative 'encounter'
require_relative 'monster'
require_relative 'battle'
require_relative 'town'
require_relative 'treasure'

class Map
  TILE_SYMBOLS = {
    '.' => '.',
    '#' => '#',
    '~' => '~',
    'T' => 'T',
    'B' => 'B'
  }.freeze

  def initialize(player)
    @player = player
  end

  def run
    area_key = @player.current_area
    area = Area[area_key]
    pos = @player.position || area.player_start.dup
    @player.position = pos
    ensure_treasures(area)

    loop do
      draw(area, pos)
      input = read_key
      new_pos = move(pos, input)

      case input
      when 'm', 'menu'
        field_menu(area)
        area = Area[@player.current_area]
        pos = @player.position
        next
      when 'q', 'quit', 'exit'
        puts "\n  中断しますか？(y/n)"
        print "  > "
        break if gets.chomp.downcase == 'y'
        next
      end

      next unless new_pos

      nx, ny = new_pos
      tile = area.tile_at(nx, ny)

      case tile
      when 'T'
        enter_town(area)
        area = Area[@player.current_area]
        pos = @player.position
        next
      when 'B'
        result = challenge_boss(area)
        if result == :won
          next_key = Area.next_key(area.key)
          if next_key
            puts "\n  エリア#{next_key}への扉が開いた！"
            Renderer.wait(2)
            @player.current_area = next_key
            area = Area[next_key]
            pos = area.player_start.dup
            @player.position = pos
            ensure_treasures(area)
          else
            return :cleared
          end
        end
        next
      when '.'
        pos = new_pos
        @player.position = pos.dup

        if (t = find_unopened_treasure(area, nx, ny))
          open_treasure(t, area, pos)
          next
        end

        if Encounter.check?
          result = random_encounter(area)
          return :dead if result == :dead
        end
      end
    end
  end

  private

  def draw(area, pos)
    Renderer.clear
    px, py = pos

    stats = @player.current_stats
    puts "  ═══ エリア#{area.key}: #{area.name} ═══"
    puts ""

    area.height.times do |y|
      print "  |"
      area.width.times do |x|
        if x == px && y == py
          print Renderer.bold(Renderer.yellow('P'))
        elsif find_unopened_treasure(area, x, y)
          print Renderer.bold(Renderer.yellow('$'))
        else
          tile = area.tile_at(x, y)
          ch = case tile
               when '#' then Renderer.color('█', 90)
               when '~' then Renderer.cyan('~')
               when 'T' then Renderer.green('T')
               when 'B' then Renderer.red('B')
               else tile
               end
          print ch
        end
      end
      case y
      when 0  then print "|   #{Renderer.bold(@player.name)} Lv#{@player.level} [#{@player.job_name}]"
      when 1  then print "|   HP: #{@player.hp}/#{@player.max_hp}"
      when 2  then print "|   MP: #{@player.mp}/#{@player.max_mp}"
      when 3  then print "|   G:  #{@player.gold}"
      when 4  then print "|   ATK:#{@player.total_attack} DEF:#{@player.total_defense}"
      when 5  then print "|   AGI:#{@player.total_agility}"
      when 6  then print "|"
      when 7  then print "|   ── 装備 ──"
      when 8  then print "|   武器: #{@player.inventory.weapon&.name || '(なし)'}"
      when 9  then print "|   頭:   #{@player.inventory.head&.name   || '(なし)'}"
      when 10 then print "|   体:   #{@player.inventory.body&.name   || '(なし)'}"
      when 11 then print "|   脚:   #{@player.inventory.legs&.name   || '(なし)'}"
      when 12 then print "|"
      when 13 then
        s = @player.status_summary
        print "|   状態: #{s.empty? ? '正常' : Renderer.yellow(s)}"
      else print "|"
      end
      puts ""
    end
    puts ""
    puts "  T:街  B:ボス  $:宝箱  [wasd]移動  [m]メニュー  [q]中断"
    print "  > "
  end

  def ensure_treasures(area)
    @player.treasures[area.key] ||= Treasure.generate_for_area(area)
  end

  def find_unopened_treasure(area, x, y)
    (@player.treasures[area.key] || []).find { |t| !t['opened'] && t['pos'] == [x, y] }
  end

  def open_treasure(treasure, area, pos)
    msg = Treasure.open(@player, treasure)
    Renderer.clear
    draw(area, pos)
    puts ""
    puts "  ★ 宝箱を開けた！"
    puts "  #{msg}"
    puts ""
    print "  Enterで続ける..."
    gets
  end

  def read_key
    first = STDIN.getch rescue (return gets.chomp.strip.downcase)
    return first.downcase if %w[w a s d].include?(first.downcase)
    print first
    rest = gets
    return '' if rest.nil?
    (first + rest).chomp.strip.downcase
  end

  def move(pos, input)
    x, y = pos
    case input
    when 'w' then [x, y - 1]
    when 's' then [x, y + 1]
    when 'a' then [x - 1, y]
    when 'd' then [x + 1, y]
    end
  end

  def enter_town(area)
    Town[area.key].enter(@player, area.data)
  end

  def field_menu(area)
    loop do
      Renderer.clear
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "  ── フィールドメニュー ──"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "  1. ステータスを見る"
      puts "  2. 装備を確認する"
      puts "  3. アイテムを使う"
      puts "  4. 閉じる"
      print "  > "
      case gets.chomp.strip.downcase
      when '1' then show_status
      when '2' then show_equipment
      when '3' then use_item_menu
      when '4', 'exit', 'quit' then break
      end
    end
  end

  def show_status
    Renderer.clear
    p = @player
    stats = p.current_stats
    puts "  ── ステータス ──"
    puts "  名前: #{p.name}  職業: #{p.job_name}"
    puts "  Lv: #{p.level}  EXP: #{p.exp}  次まで: #{p.exp_to_next || '---'}"
    puts "  HP: #{p.hp}/#{p.max_hp}  MP: #{p.mp}/#{p.max_mp}"
    puts "  攻撃力: #{p.total_attack}  防御力: #{p.total_defense}  素早さ: #{p.total_agility}"
    puts "  所持金: #{p.gold}G"
    puts ""
    spells = p.learned_spells
    unless spells.empty?
      puts "  習得呪文: #{spells.map { |s| s['name'] }.join(', ')}"
    end
    puts ""
    puts "  Enterで戻る"
    gets
  end

  def show_equipment
    Renderer.clear
    inv = @player.inventory
    puts "  ── 装備 ──"
    puts "  武器:     #{inv.weapon ? inv.weapon.name : '(なし)'}"
    puts "  頭:       #{inv.head   ? inv.head.name   : '(なし)'}"
    puts "  上半身:   #{inv.body   ? inv.body.name   : '(なし)'}"
    puts "  下半身:   #{inv.legs   ? inv.legs.name   : '(なし)'}"
    puts ""
    puts "  Enterで戻る"
    gets
  end

  def use_item_menu
    loop do
      Renderer.clear
      items = @player.inventory.item_list
      if items.empty?
        puts "  アイテムを持っていない！"
        Renderer.wait(1)
        break
      end
      puts "  ── アイテムを使う ──"
      items.each_with_index do |(it, cnt), i|
        puts "  #{i + 1}. #{it.name} x#{cnt}"
      end
      puts "  0. もどる"
      print "  > "
      idx = gets.chomp.to_i
      break if idx == 0 || idx > items.size

      it, = items[idx - 1]
      if %w[buff_atk buff_def].include?(it.type)
        puts "  それは戦闘中しか使えない！"
        Renderer.wait(1)
        next
      end
      @player.inventory.remove_item(it.id)
      msg = it.use(@player)
      puts "  #{msg}"
      Renderer.wait(1.5)
    end
  end

  def random_encounter(area)
    monsters = Encounter.generate_group(area.key)
    Battle.new(@player, monsters).run
  end

  def challenge_boss(area)
    Renderer.clear
    puts "  ！！ ボスの気配を感じる ！！"
    puts "  挑みますか？(y/n)"
    print "  > "
    return nil unless gets.chomp.downcase == 'y'

    boss = Monster.boss_for_area(area.key)
    result = Battle.new(@player, boss, is_boss: true).run

    if result == :won
      @player.defeated_bosses << area.key
    end
    result
  end
end
