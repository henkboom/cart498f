require 'dokidoki.module'
[[ make_player, make_weapon, make_player_controller, make_pyx, make_void,
   make_filler ]]

import 'gl'

local collision = require 'collision'
local v2 = require 'dokidoki.v2'

local constants = require 'constants'
local util = require 'util'

---- Player -------------------------------------------------------------------
function make_player(game, controller, _pos)
  local self = {}

  self.pos = _pos
  self.angle = 0
  self.poly = collision.make_rectangle(6, 6)
  self.tags = {'player', 'entity'}

  local vel = v2(0, 0)
  local buffered_movement = v2(0, 0)
  local weapon = false;

  function self.update()
    if not weapon then
      weapon = make_weapon(game, self, controller)
      game.add_actor(weapon)
    end

    vel = vel * 0.85 + (controller.movement * 5) * 0.15
    self.pos = self.pos + vel
  end

  function self.handle_collision(norm)
    if v2.dot(vel, norm) < 0 then
      vel = vel - v2.project(vel, norm)
    end
  end

  function self.draw()
    glColor3d(1, 1, 1)
    glBegin(GL_QUADS)
    glVertex2d(-3, -3)
    glVertex2d( 3, -3)
    glVertex2d( 3,  3)
    glVertex2d(-3,  3)
    glEnd()
    glColor3d(1, 1, 1)
  end

  return self
end

function make_weapon(game, owner, controller)
  local self = {}

  local aim = v2(0, 0)

  local cooldown = 0

  local owner_last_pos = owner.pos

  function self.update()
    if cooldown > 0 then cooldown = cooldown - 1 end

    if v2.dot(aim, controller.aim) <= 0 then
      aim = controller.aim
    else
      aim = v2.norm(aim * 0.8 + controller.aim * 0.2)
    end

    if aim ~= v2.zero and cooldown == 0 then
      game.add_actor(make_bullet(game, owner.pos,
                                 owner.pos - owner_last_pos + aim * 10))
      cooldown = cooldown + 5
    end

    owner_last_pos = owner.pos
  end

  return self
end

function make_bullet(game, pos_, vel)
  local self = {}

  self.pos = pos_
  self.angle = 0
  self.poly = collision.make_rectangle(4, 4)
  self.tags = {'entity', 'player_bullet'}

  local life = 20

  function self.update()
    if life == 0 then self.is_dead = true end
    life = life - 1

    self.pos = self.pos + vel
  end

  function self.handle_collision(norm)
    self.is_dead = true
  end

  function self.hit()
    self.is_dead = true
  end

  function self.draw()
    glColor3d(1, 1, 1)
    glBegin(GL_QUADS)
    glVertex2d(-2, -2)
    glVertex2d( 2, -2)
    glVertex2d( 2,  2)
    glVertex2d(-2,  2)
    glEnd()
    glColor3d(1, 1, 1)
  end

  return self
end

function wasd_to_direction (w, a, s, d)
  local direction = v2((d and 1 or 0) - (a and 1 or 0),
                       (w and 1 or 0) - (s and 1 or 0))
  return direction == v2.zero and direction or v2.norm(direction)
end

function make_player_controller(game)
  local self = {}

  self.movement = v2(0, 0)
  self.aim = v2(0, 0)

  function self.pre_update ()
    self.movement = wasd_to_direction(game.is_key_down(glfw.KEY_UP),
                                      game.is_key_down(glfw.KEY_LEFT),
                                      game.is_key_down(glfw.KEY_DOWN),
                                      game.is_key_down(glfw.KEY_RIGHT))
    self.aim = wasd_to_direction(game.is_key_down(string.byte('W')),
                                 game.is_key_down(string.byte('A')),
                                 game.is_key_down(string.byte('S')),
                                 game.is_key_down(string.byte('D')))
  end

  return self
end

---- Pyxes --------------------------------------------------------------------
function make_pyx (game, pos_)
  local self = {}
  
  self.pos = pos_
  self.angle = 0
  self.poly = collision.make_rectangle(2, 2)
  self.tags = {'entity'}

  local vel = v2(0, 0)
  local follow = false
  local excited_counter = 0
  local glow_brightness = 0.5
  local glow_angle = math.random() * 360

  function self.update()
    local player = game.get_actors_by_tag('player')[1]
    local force_follow = false

    excited_counter = math.max(0, excited_counter - 1)

    if player then
      local displacement = player.pos - self.pos
      if v2.sqrmag(displacement) < 30 * 30 then
        if not follow then
          follow = player
          force_follow = true
        end
        excited_counter = 10
      end
    end

    vel = vel + util.random_v2() * (v2.mag(vel) / 3 + 0.05)
    if follow then
      local displacement = follow.pos - self.pos - vel * 10
      local sqr_dist = v2.sqrmag(displacement)
      if 100 * 100 < sqr_dist then
        follow = false
        excited_counter = 30
      elseif force_follow or 70 * 70 < sqr_dist then
        vel = vel + displacement * 0.02
      end
    end
    vel = vel * 0.98

    if v2.sqrmag(vel) > 10 * 10 then
      vel = vel / v2.mag(vel) * 10
    end

    self.pos = self.pos + vel

    glow_brightness = (glow_brightness + math.random()) / 2
  end

  function self.draw_glow()
    local opacity = (0.8 + excited_counter * 0.2) * glow_brightness
    glColor4d(1, 1, 1, opacity)
    glRotated(glow_angle, 0, 0, 1)
    game.resources.pyx_glow:draw()
    glScaled(2, 2, 1)
    glColor4d(1, 1, 1, opacity/4)
    game.resources.pyx_glow:draw()
    glColor4d(1, 1, 1, 1)
  end

  function self.draw()
    local min_size = 0
    local max_size = 1 + excited_counter/10

    glColor3d(1, 1, 1)
    glBegin(GL_QUADS)
    glVertex2d(-math.random(min_size, max_size),
               -math.random(min_size, max_size))
    glVertex2d( math.random(min_size, max_size),
               -math.random(min_size, max_size))
    glVertex2d( math.random(min_size, max_size),
                math.random(min_size, max_size))
    glVertex2d(-math.random(min_size, max_size),
                math.random(min_size, max_size))
    glEnd()
    glColor3d(1, 1, 1)
  end

  function self.handle_collision(norm)
    if v2.dot(vel, norm) < 0 then
      vel = vel - 1.5 * v2.project(vel, norm)
    end
  end

  return self
end

---- Voids --------------------------------------------------------------------
function make_void(game, _pos)
  local self = {}
  self.pos = _pos
  self.angle = 0
  self.poly = collision.make_rectangle(16, 16)
  self.tags = {'entity', 'enemy'}

  local accel = v2(0, 0)
  local vel = v2(0, 0)
  local darkness_cooldown = 0

  local hp = 10

  function self.update()
    accel = (accel * 0.7 + util.random_v2() * 0.3) / 2
    vel = (vel + accel) * 0.99
    self.pos = self.pos + vel

    local player = game.get_actors_by_tag('player')[1]
    if player and v2.sqrmag(player.pos - self.pos)
         < constants.room_width * constants.room_width then
      darkness_cooldown = darkness_cooldown - 1
    end

    if darkness_cooldown <= 0 then
      game.add_actor(make_void_darkness(game, self.pos))
      darkness_cooldown = darkness_cooldown + 20
    end

  end

  function self.hit()
    hp = hp - 1
    if hp <= 0 then
      self.is_dead = true
    end
  end

  function self.draw()
    glColor3d(0, 0, 0)
    glBegin(GL_QUADS)
    glVertex2d(-7, -9)
    glVertex2d( 9, -7)
    glVertex2d( 7,  9)
    glVertex2d(-9,  7)
    glEnd()
    glColor3d(1, 1, 1)
  end

  function self.handle_collision(norm)
    if v2.dot(vel, norm) < 0 then
      vel = vel - v2.project(vel, norm)
    end
  end

  return self
end

function make_void_darkness(game, _pos)
  local self = {}
  self.pos = _pos

  local life = 60
  local particle_cooldown = 0

  function self.update()
    life = life - 1
    if life == 0 then self.is_dead = true end

    self.pos = self.pos + util.random_v2() * 20

    particle_cooldown = particle_cooldown - 1
    if particle_cooldown <= 0 then
      game.add_actor(make_void_darkness_particle(game, self.pos))
      particle_cooldown = particle_cooldown + 10
    end
  end

  function self.draw()
  end

  return self
end

function make_void_darkness_particle(game, _pos)
  local self = {}
  self.pos = _pos

  local life = 120

  function self.update()
    life = life - 1
    if life <= 0 then
      self.is_dead = true
    end
  end

  function self.draw_dark()
    glColor4d(1, 1, 1, life/120 * 0.4)
    game.resources.darkness_big:draw()
    glColor4d(1, 1, 1, 1)
  end

  function self.draw()
    glColor4d(1, 1, 1, life/120 * 0.4)
    game.resources.darkness_small:draw()
    glColor4d(1, 1, 1, 1)
  end

  return self
end

---- Fillers ------------------------------------------------------------------

function make_filler(game, _pos)
  local self = {}
  self.pos = _pos
  self.angle = 0
  self.poly = collision.make_rectangle(20, 20)
  self.tags = {'entity', 'enemy'}

  local hp = 10

  local s_waiting, s_firing, s_reinforcing
  local state

  local max_defenders = 25
  local defenders = setmetatable({}, {__mode = "k"})

  do -- s_waiting
    local wait_left
    local defense_check_cooldown = 0

    function s_waiting ()
      wait_left = wait_left and wait_left - 1 or 180

      if wait_left == 0 then
        if defense_check_cooldown == 0 then
          local defender_count = 0
          for d in pairs(defenders) do
            if not d.is_dead then defender_count = defender_count + 1 end
          end
          if defender_count < max_defenders then
            state = s_reinforcing
          end
          defense_check_cooldown = 3
          wait_left = nil
        else
          defense_check_cooldown = defense_check_cooldown - 1
          state = s_firing
          wait_left = nil
        end
      end
    end
  end

  do -- s_firing
    local fire_rotation = 0
    local cooldown = 0
    local burst_count = nil

    function s_firing()
      burst_count = burst_count or 10

      if burst_count == 0 then
        burst_count = nil
        state = s_waiting
      else
        if cooldown ~= 0 then cooldown = cooldown - 1 end
        if cooldown == 0 then
          for i = 1, 2 do
            game.add_actor(make_filler_attacker(
              game, self.pos, v2.unit(fire_rotation) * 4))
            fire_rotation = fire_rotation + math.pi + math.pi/18
          end
          cooldown = cooldown + 5
          burst_count = burst_count - 1
        end
      end
    end
  end

  do -- s_reinforcing
    local cooldown
    local number_to_fire

    function s_reinforcing()
      if not number_to_fire then
        number_to_fire = max_defenders
        for d in pairs(defenders) do
          if not d.is_dead then
            number_to_fire = number_to_fire - 1
          end
        end
      end

      cooldown = cooldown and cooldown - 1 or 10

      if cooldown == 0 then
        local d = make_filler_defender(
          game,
          self.pos,
          v2.unit(math.random() * math.pi * 2) * (3 + 2 * math.random()))
        game.add_actor(d)
        defenders[d] = true
        number_to_fire = number_to_fire - 1
        cooldown = nil
      end

      if number_to_fire == 0 then
        number_to_fire = nil
        state = s_waiting
      end
    end
  end

  state = s_waiting

  function self.update()
    state()
  end

  function self.draw()
    glScaled(20, 20, 1)
    game.resources.debug_box:draw()
  end

  function self.hit()
    hp = hp - 1
    if hp == 0 then self.is_dead = true end
  end

  function self.handle_collision()
  end

  return self
end

function make_filler_attacker(game, _pos, vel)
  local self = {}
  self.pos = _pos
  self.angle = 0
  self.poly = collision.make_rectangle(10, 10)
  self.tags = {'entity', 'enemy'}

  local offset = util.random_v2() * 10

  function self.update()
    local target_actor = game.get_actors_by_tag('player')[1]
    if target_actor and target_actor.pos ~= self.pos then
      local distance = v2.mag(target_actor.pos - self.pos)
      local target = target_actor.pos + offset * distance / 20

      local target_vel = v2.norm(target - self.pos)*(1+math.random()*3)
      vel = vel * 0.95 + target_vel * 0.05
      self.pos = self.pos + vel
    end
  end

  function self.draw()
    glScaled(10, 10, 1)
    game.resources.debug_box:draw()
  end

  function self.handle_collision()
  end

  function self.hit()
    self.is_dead = true
  end

  return self
end

function make_filler_defender(game, _pos, vel)
  local self = {}
  self.pos = _pos
  self.angle = 0
  self.poly = collision.make_rectangle(15, 15)
  self.tags = {'entity', 'enemy'}

  local timer = 40

  function self.update()
    self.pos = self.pos + vel
    timer = timer - 1
    if timer >= 0 then
      vel = vel * timer / (timer + 1)
    end
  end

  function self.draw()
    glScaled(15, 15, 1)
    game.resources.debug_box:draw()
  end

  function self.handle_collision()
  end

  function self.hit()
    self.is_dead = true
  end


  return self
end

return get_module_exports()
