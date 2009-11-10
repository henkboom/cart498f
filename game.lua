require 'dokidoki.module'
[[ init ]]

import(require 'gl')
import(require 'glu')

local collision = require 'collision'
local v2 = require 'dokidoki.v2'

local constants = require 'constants'
local entities = require 'entities'
local level = require 'level'
local util = require 'util'


function init (game)
  -- for some dumb reason the random seed gets clobered when we open a window,
  -- so we have to do it here
  math.randomseed(os.time())

  game.resources = require 'resources'

  local obstacle_index

  game.add_actor{
    pre_update = function ()
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

    draw_setup = util.gl_setup,
    draw_glow = function ()
      glBlendFunc(GL_SRC_ALPHA, GL_ONE)
    end,
    draw_terrain = function ()
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    end,
  }

  local player_controller = entities.make_player_controller(game)
  local player = entities.make_player(game, player_controller)
  game.add_actor(player_controller)
  game.add_actor(player)

  game.add_actor(util.make_following_camera(game, player))

  level.add_area(game, v2(0, 0), 5, 5)
  obstacle_index =
    util.make_collision_index(game.get_actors_by_tag('obstacle'), 32, 5)
end

return get_module_exports()
