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

function make_collision_index(objects, cell_width, buffer)
  local cell_object = {
    poly = collision.make_rectangle(cell_width + buffer*2,
                                    cell_width + buffer*2),
    angle = 0
  }

  -- grid[i][j] holds objects relevant for collisions for the cell with lower
  -- coords (i*cell_width, j*cell_width)
  local grid = {}

  for _, o in ipairs(objects) do
    local x1, x2 = o.pos.x, o.pos.x
    local y1, y2 = o.pos.y, o.pos.y

    for _, v in ipairs(o.poly.vertices) do
      x1 = math.min(x1, o.pos.x + v.x)
      x2 = math.max(x2, o.pos.x + v.x)
      y1 = math.min(y1, o.pos.y + v.y)
      y2 = math.max(y2, o.pos.y + v.y)
    end

    for i = math.floor((x1 - buffer) / cell_width),
            math.floor((x2 + buffer) / cell_width) do
      for j = math.floor((y1 - buffer) / cell_width),
              math.floor((y2 + buffer) / cell_width) do
        cell_object.pos = v2((i + 0.5) * cell_width, (j + 0.5) * cell_width)
        if collision.collide(cell_object, o) then
          grid[i] = grid[i] or {}
          grid[i][j] = grid[i][j] or {}
          table.insert(grid[i][j], o)
        end
      end
    end
  end

  local self = {}

  self = {
    lookup = function (pos)
      local i = math.floor(pos.x / cell_width)
      local j = math.floor(pos.y / cell_width)
      return grid[i] and grid[i][j] or {}
    end,
    draw_debug = function (pos)
      local i = math.floor(pos.x / cell_width)
      local j = math.floor(pos.y / cell_width)
      cell_object.pos = v2((i + 0.5) * cell_width, (j + 0.5) * cell_width)
      glBegin(GL_LINE_LOOP)
      for _, v in ipairs(cell_object.poly.vertices) do
        glVertex2d(v.x + cell_object.pos.x, v.y + cell_object.pos.y)
      end
      glEnd()
      for _, o in ipairs(self.lookup(pos)) do
        glPushMatrix()
        glTranslated(o.pos.x, o.pos.y, 0)
        o.draw_debug()
        glPopMatrix()
      end
    end
  }

  return self
end


function init (game)

  local obstacle_index

  game.add_actor{
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

  level.add_area(game, v2(0, 0), 7, 7)
  obstacle_index =
    make_collision_index(game.get_actors_by_tag('obstacle'), 32, 5)
end

return get_module_exports()
