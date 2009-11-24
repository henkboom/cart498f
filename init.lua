--dokidoki_disable_debug = true
require 'dokidoki.module' [[]]

require 'glfw'

local actor_scene = require 'dokidoki.actor_scene'
local kernel = require 'dokidoki.kernel'
local v2 = require 'dokidoki.v2'

local collision = require 'collision'
local C = require 'constants'
local entities = require 'entities'
local level = require 'level'
local util = require 'util'

import(require 'gl')
import(require 'glu')

update_phases = {'pre_update', 'update', 'collision_check', 'post_update'}
draw_phases = {'draw_setup', 'draw_dark', 'draw_glow', 'draw_terrain', 'draw'}

function init_drawing(game)
  game.add_actor{
    draw_setup = function ()
      glClearColor(0.2, 0.2, 0.2, 0)
      glClear(GL_COLOR_BUFFER_BIT)
      glEnable(GL_BLEND)
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      glMatrixMode(GL_PROJECTION)
      glLoadIdentity()
      glOrtho(0, C.width, 0, C.height, 1, -1)
      glMatrixMode(GL_MODELVIEW)
      glLoadIdentity()
      glColor3d(1, 1, 1)
    end,
    draw_glow = function ()
      glBlendFunc(GL_SRC_ALPHA, GL_ONE)
    end,
    draw_terrain = function ()
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    end,
  }
end

function init_mouse_input(game)
  local center

  local mouse_movement = v2(0, 0)
  
  game.add_actor{
    pre_update = function ()
      if center then
        mouse_movement = v2(glfw.GetMousePos()) - center
        print(mouse_movement)
      end
      center = v2(kernel.get_width()/2, kernel.get_height()/2)
      glfw.SetMousePos(center.x, center.y)
    end
  }
end

function init_collision(game)
  local obstacle_index

  game.add_actor{
    pre_update = function ()
      obstacle_index = obstacle_index or
        util.make_collision_index(game.get_actors_by_tag('obstacle'), 32, 5)
    end,
    collision_check = function ()
      for _, e in ipairs(game.get_actors_by_tag('entity')) do
        for _, o in ipairs(obstacle_index.lookup(e.pos)) do
          local correction = collision.collide(e, o)
          if correction then
            e.pos = e.pos + correction
            e.handle_collision(v2.norm(correction))
          end
        end
      end
      for _, e in ipairs(game.get_actors_by_tag('enemy')) do
        for _, b in ipairs(game.get_actors_by_tag('player_bullet')) do
          local correction = collision.collide(e, b)
          if correction then
            e.hit()
            b.hit()
          end
        end
      end
    end,
  }
end

function init (game)
  -- for some dumb reason the random seed gets clobered when we open a window,
  -- so we have to do it here
  math.randomseed(os.time())

  game.resources = require 'resources'

  init_drawing(game)
  init_mouse_input(game)
  init_collision(game)

  local player_pos = v2(C.room_width * 2.5, C.room_height/2)

  local player_controller = entities.make_player_controller(game)
  local player = entities.make_player(game, player_controller, player_pos)
  game.add_actor(player_controller)
  game.add_actor(player)

  --game.add_actor(entities.make_filler(game, player_pos + v2(100, 100)))

  game.add_actor(util.make_following_camera(game, player))

  level.add_area(game, v2(0, 0), 5, 5)
end

kernel.set_video_mode(C.width, C.height)
kernel.set_ratio(C.width/C.height)
kernel.start_main_loop(
  actor_scene.make_actor_scene(update_phases, draw_phases, init))
