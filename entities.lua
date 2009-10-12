require 'dokidoki.module'
[[ make_player, make_weapon, make_player_controller, make_pyx ]]

import 'gl'

local collision = require 'collision'
local v2 = require 'dokidoki.v2'

local util = require 'util'

---- Player -------------------------------------------------------------------
function make_player(game, controller)
  local self = {}

  self.pos = v2(150, 150)
  self.angle = 0
  self.poly = collision.make_rectangle(6, 6)
  self.tags = {'entity'}
  local vel = v2(0, 0)

  local buffered_movement = v2(0, 0)

  function self.update()
    vel = vel * 0.8 + (controller.movement * 5) * 0.2
    self.pos = self.pos + vel
  end

  function self.handle_collision(norm)
  end

  function self.draw()
    glBegin(GL_QUADS)
    glVertex2d(-3, -3)
    glVertex2d( 3, -3)
    glVertex2d( 3,  3)
    glVertex2d(-3,  3)
    glEnd()
  end

  return self
end

function make_weapon(game, owner, controller)
  local self = {}

  local aim = v2(0, 0)

  local cooldown = 0

  function self.update()
    if cooldown > 0 then cooldown = cooldown - 1 end

    if v2.dot(aim, controller.aim) <= 0 then
      aim = controller.aim
    else
      aim = v2.norm(aim * 0.8 + controller.aim * 0.2)
    end
    if aim ~= v2.zero and cooldown == 0 then
      game.add_actor(make_bullet(game, owner.pos, aim * 10))
      cooldown = cooldown + 5
    end
  end

  return self
end

function make_bullet(game, pos_, vel)
  local self = {}

  self.pos = pos_
  self.angle = 0
  self.poly = collision.make_rectangle(4, 4)
  self.tags = {'entity'}

  local life = 20

  function self.update()
    if life == 0 then self.is_dead = true end
    life = life - 1

    self.pos = self.pos + vel
  end

  function self.handle_collision(norm)
    self.is_dead = true
  end

  function self.draw()
    glBegin(GL_QUADS)
    glVertex2d(-2, -2)
    glVertex2d( 2, -2)
    glVertex2d( 2,  2)
    glVertex2d(-2,  2)
    glEnd()
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
function make_pyx (game, player, pos_)
  local self = {}
  
  self.pos = pos_
  self.angle = 0
  self.poly = collision.make_rectangle(2, 2)
  self.tags = {'entity'}

  local vel = v2(0, 0)
  local follow = nil

  function self.update()
    local displacement = player.pos - self.pos
    if v2.sqrmag(displacement) < 30 * 30 then
      follow = player
    end

    vel = vel + util.random_v2() * (v2.mag(vel) / 4 + 0.05)
    if follow then
      local displacement = follow.pos - self.pos - vel * 10
      local sqr_dist = v2.sqrmag(displacement)
      if 20 * 20 < sqr_dist then
        vel = vel + displacement * 0.05
      end
    end
    vel = vel * 0.98
    self.pos = self.pos + vel
  end

  function self.draw()
    glBegin(GL_QUADS)
    glVertex2d(-1, -1)
    glVertex2d( 1, -1)
    glVertex2d( 1,  1)
    glVertex2d(-1,  1)
    glEnd()
  end

  function self.handle_collision()
  end

  return self
end

return get_module_exports()