require 'ruby2d'

set title: 'Mario in Ruby2D - Restart or Exit on Game Over / Level Complete'
set width: 800, height: 600

$scene_width = 3000
$max_offset = $scene_width - Window.width

GRAVITY = 0.5
PLAYER_SPEED = 5
JUMP_STRENGTH = 10
GROUND_Y = 550

$score = 0
$world_offset = 0
$level_complete = false
$game_over = false

$status_text = nil
$restart_button = nil
$exit_button = nil
$restart_text = nil
$exit_text = nil
$wall = nil

def remove_object(obj)
  if obj.respond_to?(:remove)
    obj.remove
  elsif obj.is_a?(Array)
    obj.each { |el| remove_object(el) }
  end
end

def init_game
  $score = 0
  
  $player = Image.new('assets/playerFrame1.png',
                      width: 30, height: 50, x: 50, y: GROUND_Y - 50)
  
  $obstacles = []
  $obstacles << Image.new('assets/block.png',
                          x: 300, y: GROUND_Y - 30, width: 30, height: 30)
  $obstacles << Image.new('assets/block.png',
                          x: 1200, y: GROUND_Y - 30, width: 30, height: 30)
  $obstacles << Image.new('assets/block.png',
                          x: 2500, y: GROUND_Y - 30, width: 30, height: 30)
  
  $holes = [{ x: 500,  width: 100 },
            { x: 1700, width: 150 },
            { x: 2200, width: 120 }]
  
  $coins = []
  $coins << Image.new('assets/coin.png', x: 350,  y: GROUND_Y - 120, width: 20, height: 20)
  $coins << Image.new('assets/coin.png', x: 150,  y: GROUND_Y - 70,  width: 20, height: 20)
  $coins << Image.new('assets/coin.png', x: 800,  y: GROUND_Y - 120, width: 20, height: 20)
  $coins << Image.new('assets/coin.png', x: 1100, y: GROUND_Y - 70,  width: 20, height: 20)
  $coins << Image.new('assets/coin.png', x: 1400, y: GROUND_Y - 120, width: 20, height: 20)
  $coins << Image.new('assets/coin.png', x: 1800, y: GROUND_Y - 120, width: 20, height: 20)
  $coins << Image.new('assets/coin.png', x: 2100, y: GROUND_Y - 70,  width: 20, height: 20)
  $coins << Image.new('assets/coin.png', x: 2400, y: GROUND_Y - 120, width: 20, height: 20)
  $coins << Image.new('assets/coin.png', x: 2700, y: GROUND_Y - 70,  width: 20, height: 20)
  
  $score_text = Text.new("Score: #{$score}", x: 10, y: 10, size: 20, color: 'white')
  
  $velocity_y = 0
  $on_ground = false
  
  $ground_segments = []
  ground_start = 0
  $holes.sort_by { |h| h[:x] }.each do |h|
    if ground_start < h[:x]
      seg_width = h[:x] - ground_start
      seg = Image.new('assets/ground.png', x: ground_start, y: GROUND_Y,
                      width: seg_width, height: Window.height - GROUND_Y)
      $ground_segments << seg
    end
    ground_start = h[:x] + h[:width]
  end
  if ground_start < $scene_width
    seg = Image.new('assets/ground.png', x: ground_start, y: GROUND_Y,
                    width: $scene_width - ground_start, height: Window.height - GROUND_Y)
    $ground_segments << seg
  end
  
  [$status_text, $restart_button, $exit_button, $restart_text, $exit_text, $wall].each { |el| remove_object(el) }
  $status_text = nil
  $restart_button = nil
  $exit_button = nil
  $restart_text = nil
  $exit_text = nil
  $wall = nil
  
  $level_complete = false
  $game_over = false
  $world_offset = 0
end

init_game

$keys = {}
on :key_down do |event|
  $keys[event.key] = true
end
on :key_up do |event|
  $keys[event.key] = false
end

def reset_game
  [$player, $obstacles, $coins, $ground_segments, $score_text, $status_text,
   $restart_button, $exit_button, $restart_text, $exit_text, $wall].each { |el| remove_object(el) }
  init_game
end

update do
  if $level_complete || $game_over
    if $wall && $player.x + $player.width >= $wall.x
      $level_complete = true
      $status_text = Text.new("Game Complete! Score: #{$score}", x: 200, y: 200, size: 40, color: 'green')
    end
    next
  end
  
  $player.x -= PLAYER_SPEED if $keys['left'] || $keys['a']
  $player.x += PLAYER_SPEED if $keys['right'] || $keys['d']
  $player.x = 0 if $player.x < 0  # Blokujemy wychodzenie na lewą stronę
  
  max_offset = $max_offset
  if ($keys['right'] || $keys['d']) && $player.x > 300 && $world_offset < max_offset
    dx = $player.x - 300
    dx = max_offset - $world_offset if $world_offset + dx > max_offset
    $player.x = 300
    $obstacles.each { |obs| obs.x -= dx }
    $coins.each { |coin| coin.x -= dx }
    $ground_segments.each { |seg| seg.x -= dx }
    $holes.each { |h| h[:x] -= dx } if $holes && $holes.is_a?(Array)
    $world_offset += dx
  end
  
  if $world_offset >= max_offset && !$wall
    $wall = Rectangle.new(x: Window.width - 20, y: 0, width: 20, height: Window.height, color: 'gray')
  end
  
  if $wall && $player.x + $player.width >= $wall.x
    $level_complete = true
    $status_text = Text.new("Game Complete! Score: #{$score}", x: 200, y: 200, size: 40, color: 'green')
    $restart_button = Rectangle.new(x: 350, y: 300, width: 100, height: 50, color: 'blue')
    $restart_text = Text.new("Restart", x: 365, y: 315, size: 20, color: 'white')
    $exit_button = Rectangle.new(x: 350, y: 370, width: 100, height: 50, color: 'red')
    $exit_text = Text.new("Exit", x: 375, y: 385, size: 20, color: 'white')
  end
  
  if ($keys['up'] || $keys['w'] || $keys['space']) && $on_ground
    $velocity_y = -JUMP_STRENGTH
    $on_ground = false
  end
  
  $velocity_y += GRAVITY
  $player.y += $velocity_y
  
  $obstacles.each do |obs|
    if $player.x < obs.x + obs.width && $player.x + $player.width > obs.x &&
       $player.y < obs.y + obs.height && $player.y + $player.height > obs.y
      $game_over = true
      $score = 0
      $score_text.text = "Score: 0"
      $status_text = Text.new("Game Over! Score: #{$score}", x: 200, y: 200, size: 40, color: 'red')
      $restart_button = Rectangle.new(x: 350, y: 300, width: 100, height: 50, color: 'blue')
      $restart_text = Text.new("Restart", x: 365, y: 315, size: 20, color: 'white')
      $exit_button = Rectangle.new(x: 350, y: 370, width: 100, height: 50, color: 'red')
      $exit_text = Text.new("Exit", x: 375, y: 385, size: 20, color: 'white')
    end
  end
  
  if $player.y + $player.height >= GROUND_Y
    center_x = $player.x + $player.width / 2.0
    over_hole = $holes.any? { |h| center_x > h[:x] && center_x < (h[:x] + h[:width]) }
    unless over_hole
      $player.y = GROUND_Y - $player.height
      $velocity_y = 0
      $on_ground = true
    end
  end
  
  if $player.y > Window.height
    $game_over = true
    $score = 0
    $score_text.text = "Score: 0"
    $status_text = Text.new("Game Over! Score: #{$score}", x: 200, y: 200, size: 40, color: 'red')
    $restart_button = Rectangle.new(x: 350, y: 300, width: 100, height: 50, color: 'blue')
    $restart_text = Text.new("Restart", x: 365, y: 315, size: 20, color: 'white')
    $exit_button = Rectangle.new(x: 350, y: 370, width: 100, height: 50, color: 'red')
    $exit_text = Text.new("Exit", x: 375, y: 385, size: 20, color: 'white')
  end
  
  $coins.each_with_index do |coin, idx|
    if $player.x < coin.x + coin.width &&
       $player.x + $player.width > coin.x &&
       $player.y < coin.y + coin.height &&
       $player.y + $player.height > coin.y
      $score += 10
      $score_text.text = "Score: #{$score}"
      coin.remove
      $coins.delete_at(idx)
    end
  end
end

on :mouse_down do |event|
  if ($level_complete || $game_over) && $restart_button &&
     event.x >= $restart_button.x && event.x <= $restart_button.x + $restart_button.width &&
     event.y >= $restart_button.y && event.y <= $restart_button.y + $restart_button.height
    reset_game
  end

  if ($level_complete || $game_over) && $exit_button &&
     event.x >= $exit_button.x && event.x <= $exit_button.x + $exit_button.width &&
     event.y >= $exit_button.y && event.y <= $exit_button.y + $exit_button.height
    close
  end
end

show
