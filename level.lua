require 'dokidoki.module'
[[ add_area ]]

import 'gl'
import 'dokidoki.base'

local collision = require 'collision'
local v2 = require 'dokidoki.v2'

local constants = require 'constants'
local entities = require 'entities'

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

function add_area (game, pos, x_cells, y_cells)
  local cells = {}
  local edges = {}

  for i = 1, x_cells do
    cells[i] = {}
    for j = 1, y_cells do
      cells[i][j] = {'wall', 'wall', 'wall', 'wall'}
      if i ~= 1 then
        table.insert(edges, {cells[i-1][j], cells[i][j], orientation=1})
      end
      if j ~= 1 then
        table.insert(edges, {cells[i][j-1], cells[i][j], orientation=2})
      end
    end
  end

  for edge in iterate_passages(edges) do
    edge[1][edge.orientation] = 'door'
    edge[2][edge.orientation + 2] = 'door'
  end

  for i = 1, x_cells do
    for j = 1, y_cells do
      add_room(game,
               pos + v2((i-1) * constants.room_width,
                        (j-1) * constants.room_height),
               cells[i][j]);
    end
  end
end

vert_wall = collision.make_rectangle(constants.wall_thickness, constants.room_height + constants.wall_thickness)
horiz_wall = collision.make_rectangle(constants.room_width + constants.wall_thickness, constants.wall_thickness)

vert_half_wall = collision.make_rectangle(constants.wall_thickness, constants.room_height / 2 - constants.wall_thickness)
horiz_half_wall = collision.make_rectangle(constants.room_width / 2 - constants.wall_thickness, constants.wall_thickness)

function add_wall(game, pos, type, orientation)
  local rw = constants.room_width
  local rh = constants.room_height
  local wt = constants.wall_thickness

  if type == 'wall' then
    if orientation == 'horiz' then
      game.add_actor(make_obstacle(game, pos, 0, horiz_wall))
    else
      game.add_actor(make_obstacle(game, pos, 0, vert_wall))
    end
  elseif type == 'door' then
    if orientation == 'horiz' then
      game.add_actor(
        make_obstacle(game, pos-v2(rw/4+wt/2,0), 0, horiz_half_wall))
      game.add_actor(
        make_obstacle(game, pos+v2(rw/4+wt/2,0), 0, horiz_half_wall))
    else
      game.add_actor(
        make_obstacle(game, pos-v2(0,rh/4+wt/2), 0, vert_half_wall))
      game.add_actor(
        make_obstacle(game, pos+v2(0,rh/4+wt/2), 0, vert_half_wall))
    end
  else
    error('unrecognized wall type "' .. type .. '"')
  end
end

function add_room(game, pos, sides)
  local rw = constants.room_width
  local rh = constants.room_height

  local pyx_count = math.random(-4, 0);

  add_wall(game, pos + v2(rw, rh/2), sides[1], 'vert')
  add_wall(game, pos + v2(rw/2, rh), sides[2], 'horiz')
  add_wall(game, pos + v2(0, rh/2), sides[3], 'vert')
  add_wall(game, pos + v2(rw/2, 0), sides[4], 'horiz')
  game.add_actor(make_floor_actor(game, pos, game.resources.room_backgrounds[1]))

  for i = 1, 4 do
    if sides[i] == 'wall' then pyx_count = pyx_count + 2 end
  end

  for i = 1, pyx_count do
    game.add_actor(entities.make_pyx(
      game,
      pos + v2(math.random(rw/3, 2*rw/3), math.random(rh/3, 2*rh/3))))
  end
  game.add_actor(entities.make_void(game, pos + v2(rw/2, rh/2)))
end

function iterate_passages(edges)
  local node_groups = {}
  edges = irandomize(edges)
  local i = 1

  return function ()
    local edge

    repeat
      if i > #edges then return nil end
      edge = edges[i]
      i = i + 1
      node_groups[edge[1]] = node_groups[edge[1]] or {edge[1]}
      node_groups[edge[2]] = node_groups[edge[2]] or {edge[2]}
    until node_groups[edge[1]] ~= node_groups[edge[2]]

    local union = iconcat(node_groups[edge[1]], node_groups[edge[2]])
    for _, node in ipairs(union) do
      node_groups[node] = union
    end

    assert(node_groups[edge[1]] == node_groups[edge[2]])

    return edge
  end
end

function make_floor_actor(game, pos, sprite)
  local self = {}
  self.pos = pos

  function self.draw_terrain()
    sprite:draw()
  end

  return self
end

function make_obstacle (game, pos, angle, poly)
  local self = {}
  self.pos = pos
  self.angle = angle
  self.poly = poly
  self.tags = {'obstacle'}

  function self.draw()
    glColor3d(0, 0, 0)
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
