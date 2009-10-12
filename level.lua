require 'dokidoki.module'
[[ load_level ]]

import 'gl'

local v2 = require 'dokidoki.v2'

function load_level(game, level)
  local level_handlers =
  {
    obstacle = function (data)
      local points = imap(function (p) return v2(unpack(p)) end, data)
      local pos, poly = collision.points_to_polygon(points)
      game.add_actor(make_obstacle(game, pos, 0, poly))
    end
  }
  for _, data in ipairs(level) do
    level_handlers[data.type](data)
  end
end

function make_obstacle (game, pos, angle, poly)
  local self = {}
  self.pos = pos
  self.angle = angle
  self.poly = poly
  self.tags = {'obstacle'}

  function self.draw()
    glColor3d(0.9, 0.9, 0.9)
    glBegin(GL_POLYGON)
    for _, v in ipairs(self.poly.vertices) do
      glVertex2d(v.x, v.y)
    end
    glEnd()
    glColor3d(1, 1, 1)
  end

  return self
end

return get_module_exports()
