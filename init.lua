--dokidoki_disable_debug = true
require 'dokidoki.module' [[]]

local actor_scene = require 'dokidoki.actor_scene'
local kernel = require 'dokidoki.kernel'

local constants = require 'constants'
local game = require 'game'

kernel.set_video_mode(constants.width, constants.height)
kernel.set_ratio(constants.width/constants.height)
kernel.start_main_loop(actor_scene.make_actor_scene(
  {'pre_update', 'update', 'collision_check', 'post_update'},
  {'draw_setup', 'draw_dark', 'draw_glow', 'draw_terrain', 'draw'},
  game.init))
