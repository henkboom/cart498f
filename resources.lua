local g = require 'dokidoki.graphics'
local C = require 'constants'

local room_size = {C.room_width, C.room_height}

return {
  room_backgrounds = {
    g.sprite_from_image('rooms/1.png', room_size)
  },
  pyx_glow = g.sprite_from_image('sprites/pyx_glow.png', {128, 128}, 'center'),
  darkness_small =
    g.sprite_from_image('sprites/darkness.png', {48, 48}, 'center'),
  darkness_big =
    g.sprite_from_image('sprites/darkness.png', {192, 192}, 'center'),
  darkness_big =
    g.sprite_from_image('sprites/darkness.png', {192, 192}, 'center'),
  debug_box =
    g.sprite_from_image('sprites/debug_box.png', {1, 1}, 'center'),
}
