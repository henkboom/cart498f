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

  local obstacle_index

  game.add_actor{
    pre_update = function ()
    end,
    collision_check = function ()
      local entities = game.get_actors_by_tag('entity')
      for _, e in ipairs(entities) do
        for _, o in ipairs(obstacle_index.lookup(e.pos)) do
          local correction = collision.collide(e, o)
          if correction then
            e.pos = e.pos + correction
            e.handle_collision(v2.norm(correction))
          end
        end
      end
    end,

    draw_setup = util.gl_setup,
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
