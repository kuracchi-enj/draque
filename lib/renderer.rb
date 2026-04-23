module Renderer
  def self.clear
    print "\e[H\e[2J"
    STDOUT.flush
  end

  def self.wait(seconds)
    sleep(seconds)
  end

  def self.color(text, code)
    "\e[#{code}m#{text}\e[0m"
  end

  def self.red(text)     = color(text, 31)
  def self.green(text)   = color(text, 32)
  def self.yellow(text)  = color(text, 33)
  def self.blue(text)    = color(text, 34)
  def self.magenta(text) = color(text, 35)
  def self.cyan(text)    = color(text, 36)
  def self.white(text)   = color(text, 37)
  def self.bold(text)    = color(text, 1)

  def self.title_banner
    puts bold(cyan("  ╔═══════════════════════════╗"))
    puts bold(cyan("  ║       D r a Q u e         ║"))
    puts bold(cyan("  ║   Ruby Quest Adventure    ║"))
    puts bold(cyan("  ╚═══════════════════════════╝"))
    puts ""
  end

  def self.divider
    puts "  " + "─" * 30
  end
end
