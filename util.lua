require 'dokidoki.module'
[[ random_v2, gl_setup, make_following_camera, make_collision_index ]]

import 'gl'
import 'glu'

local collision = require 'collision'
local v2 = require 'dokidoki.v2'

local constants = require 'constants'

function random_v2()
  return v2.unit(math.random() * 2 * math.pi) * math.sqrt(math.random())
end

function gl_setup()
    glClearColor(0.25, 0.25, 0.25, 0)
    glClear(GL_COLOR_BUFFER_BIT)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    glOrtho(0, constants.width, 0, constants.height, 1, -1)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glColor3d(1, 1, 1)
end

function make_following_camera (game, actor)
  local self = {}
  local pos = actor.pos

  local function clamped(v)
    local rw = constants.room_width
    local rh = constants.room_height

    local center = v2(math.floor(v.x/rw) * rw + rw/2,
                      math.floor(v.y/rh) * rh + rh/2)
    return center * 0.7 + v * 0.3
  end

  function self.post_update ()
    pos = pos * 0.8 + clamped(actor.pos) * 0.2
  end

  function self.draw_setup ()
    glTranslated(constants.width/2 - pos.x, constants.height/2 - pos.y, 0)
  end

  return self
end

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

return get_module_exports()
