--dokidoki_disable_debug = true
require 'dokidoki.module' [[]]

import(require 'gl')
import(require 'glu')
import(require 'dokidoki.base')

local actor_scene = require 'dokidoki.actor_scene'
local collision = require 'collision'
local kernel = require 'dokidoki.kernel'
local v2 = require 'dokidoki.v2'

local constants = require 'constants'
local entities = require 'entities'
local util = require 'util'

function init (game)
  game.add_actor{
    collision_check = function ()
      local entities = game.get_actors_by_tag('entity')
      local obstacles = game.get_actors_by_tag('obstacle')
      for _, e in ipairs(entities) do
        for _, o in ipairs(obstacles) do
          local correction = collision.collide(e, o)
          if correction then
            e.pos = e.pos + correction
            e.handle_collision(v2.norm(correction))
          end
        end
      end
    end,

    draw_setup = util.gl_setup,

    draw_terrain = function ()
      glBegin(GL_LINES)
      for i = -1000, 1000, 100 do
        glColor3d(0.5, 0.5, 0.5)
        glVertex2d(-1000, i)
        glVertex2d( 1000, i+100)
        glVertex2d(i, -1000)
        glVertex2d(i-100,  1000)
      end
      glColor3d(1, 1, 1)
      glEnd()
    end,
  }

  local player_controller = entities.make_player_controller(game)
  local player = entities.make_player(game, player_controller)
  game.add_actor(player_controller)
  game.add_actor(player)
  game.add_actor(entities.make_weapon(game, player, player_controller))

  game.add_actor(util.make_following_camera(game, player))

  for i = 1, 100 do
    game.add_actor(entities.make_pyx(game, player, v2(math.random(100, 300), math.random(100, 300))))
  end
end

---- Init ---------------------------------------------------------------------

kernel.set_video_mode(constants.width, constants.height)
kernel.set_ratio(constants.width/constants.height)
kernel.start_main_loop(actor_scene.make_actor_scene(
  {'pre_update', 'update', 'collision_check', 'post_update'},
  {'draw_setup', 'draw_terrain', 'draw'},
  init))
