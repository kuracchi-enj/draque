require 'fileutils'
$LOAD_PATH.unshift(File.join(__dir__, 'lib'))

require_relative 'lib/game'

Game.new.start
