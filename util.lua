require 'dokidoki.module'
[[ random_v2, gl_setup, make_following_camera ]]

import 'gl'
import 'glu'

local constants = require 'constants'
local v2 = require 'dokidoki.v2'

function random_v2()
  return v2.unit(math.random() * 2 * math.pi) * math.sqrt(math.random())
end

function gl_setup()
    glClearColor(0, 0, 0, 0)
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

  function self.post_update ()
    pos = pos * 0.95 + actor.pos * 0.05
  end

  function self.draw_setup ()
    glTranslated(constants.width/2 - pos.x, constants.height/2 - pos.y, 0)
  end

  return self
end

return get_module_exports()
