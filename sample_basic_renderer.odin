package sample_basic_renderer

import platform  "khasix:game_platform"
import renderer  "khasix:basic_renderer"
import assets    "khasix:assets"
import "core:log"
import "core:fmt"

ROOT_PATH :: #config(SAMPLES_ROOT_PATH, "..")
ASSETS_PATH :: ROOT_PATH + "/assets"
TEXTURES_PATH :: ASSETS_PATH + "/textures"
STATIC_MESHES_PATH :: ASSETS_PATH + "/static_meshes"

Scene_Info :: struct {
  target: renderer.Target,
  init:   proc() -> bool,
  render: proc(),
}

Scene :: enum {
  Lines,
  Targets,
  Basic_Quads,
  Quads_Batched,
}

Game_State :: struct {
  platform_state: platform.State,
  renderer_state: renderer.State,

  current_scene:  Scene,
  draw_commands:  renderer.Draw_Commands,

  texture_emerald_peaks:                 renderer.Texture_Handle,
  texture_art_deco_gatsby:               renderer.Texture_Handle,
  texture_cornwall_toned_wood_flooring:  renderer.Texture_Handle,
  texture_nero_flooring_tiles:           renderer.Texture_Handle,
  texture_yale_blue_mosaic_wooden_floor: renderer.Texture_Handle,

  scene_target_extra_target: renderer.Target,

  // Utility for scenes that want to grab a random texture
  all_textures: [dynamic]renderer.Texture_Handle,
}

game: ^Game_State

main :: proc() {
  logger := log.create_console_logger()
  defer log.destroy_console_logger(logger)
  context.logger = logger

  game = new(Game_State, context.allocator)
  defer free(game, context.allocator)

  defer platform.shutdown(&game.platform_state)
  if !platform.init(&game.platform_state, "Basic Renderer Sample", {1920, 1080}) {
    return
  }

  defer renderer.shutdown(&game.renderer_state)
  if !renderer.init(
    &game.renderer_state,
    platform.window_native_handle(),
  ) {
    return
  }

  if !load_textures() {
    return
  }

  {
    sm: assets.Static_Mesh
    ok := assets.static_mesh_init(
      &sm, STATIC_MESHES_PATH + "/weird_shapes.khsm",
      context.temp_allocator, context.temp_allocator)
    assert(ok)
  }

  for &scene in scenes {
    if !renderer.target_init(&scene.target, platform.window_client_size()) {
      return
    }
    scene.init()
  }

  renderer.draw_commands_init(&game.draw_commands)

  for !platform.window_should_close() {
    platform.update()

    renderer.new_frame(platform.window_client_size())
    renderer.draw_commands_clear(&game.draw_commands)

    if platform.button_pressed(.Arrow_Left) {
      i := cast(int)game.current_scene - 1
      if i < 0 {
        i = cast(int)max(Scene)
      }
      game.current_scene = cast(Scene)i
    }
    if platform.button_pressed(.Arrow_Right) {
      i := cast(int)game.current_scene + 1
      if i > cast(int)max(Scene) {
        i = cast(int)min(Scene)
      }
      game.current_scene = cast(Scene)i
    }

    scenes[game.current_scene].render()

    renderer.draw_commands_submit(&game.draw_commands, scenes[game.current_scene].target)
    if !renderer.end_frame_and_present(scenes[game.current_scene].target) {
      break
    }

  }
}

scene_render_basic_quads :: proc() {

}

load_textures :: proc() -> bool {
  texture_create :: proc(filepath: string) -> (handle: renderer.Texture_Handle, ok: bool) {
    handle = renderer.texture_create_color(filepath, flags = {}) or_return
    append(&game.all_textures, handle)
    return handle, true
  }

  game.texture_emerald_peaks = texture_create(TEXTURES_PATH + "/emerald_peaks.png") or_return
  game.texture_art_deco_gatsby = texture_create(TEXTURES_PATH + "/art_deco_gatsby.png") or_return
  game.texture_cornwall_toned_wood_flooring = texture_create(TEXTURES_PATH + "/cornwall_toned_wood_flooring.png") or_return
  game.texture_nero_flooring_tiles = texture_create(TEXTURES_PATH + "/nero_flooring_tiles.png") or_return
  game.texture_yale_blue_mosaic_wooden_floor = texture_create(TEXTURES_PATH + "/yale_blue_mosaic_wooden_floor.png") or_return

  return true
}

scenes := [Scene]Scene_Info {

  .Basic_Quads = {
    init = proc() -> bool {
      return true
    },

    render = proc() {
      renderer.render_quad(
        &game.draw_commands,
        min = { 20, 20 },
        max = { 500, 300 },
        tint = {1, 1, 1, 1},
        depth = 0.1,
        texture_handle = game.texture_emerald_peaks,
      )
      renderer.render_quad(
        &game.draw_commands,
        min = { 600, 600 },
        max = { 800, 800 },
        tint = {1, 1, 1, 1},
        depth = 0.2,
      )
      renderer.render_quad(
        &game.draw_commands,
        min = { 20, 20 },
        max = { 100, 100 },
        tint = { 0, 1, 0, 1 },
        depth = 0.0,
      )
    }
  },

  .Quads_Batched = {
    init = proc() -> bool {
      return true
    },

    render = proc() {

      draw_lots_of_quads :: proc(
        count: int,
        start_pos: [2]f32,
        colored := false,
        textured := false,
        quad_size := [2]f32 { 100, 100 },
        scissor := renderer.Scissor{},
      ) {
        pos := start_pos
        offset := quad_size / 3
        for i in 0 ..< count {

          color := WHITE
          if colored {
            color = COLORS[i % len(COLORS)]
          }

          texture: renderer.Texture_Handle
          if textured {
            texture = game.all_textures[i % len(game.all_textures)]
          }

          renderer.render_quad(
            &game.draw_commands,
            min = pos,
            max = pos + quad_size,
            tint = color,
            texture_handle = texture,
            depth = cast(f32)i / cast(f32)count,
            scissor = scissor,
          )

          pos += offset
        }
      }

      // Colored quads
      draw_lots_of_quads(10, { 20, 20 }, textured = true, quad_size = { 200, 200 })
      draw_lots_of_quads(20, { 400, 20 }, colored = true)
      draw_lots_of_quads(10, { 520, 20  }, textured = true)

      draw_lots_of_quads(100, { 20, 20 }, quad_size = { 20, 20 })
      draw_lots_of_quads(100, { 250, 20 }, colored = true, quad_size = { 20, 20 })
      draw_lots_of_quads(100, { 480, 20 }, textured = true, quad_size = { 20, 20 })

      draw_lots_of_quads(100, { 20, 180 }, textured = true, quad_size = { 30, 30 })
      draw_lots_of_quads(200, { 400, 180 }, textured = true, colored = true, quad_size = { 15, 15 })
      draw_lots_of_quads(200, { 20, 350 }, colored = true, quad_size = { 15, 15 })

      draw_lots_of_quads(100, { 400, 350 }, colored = true, textured = true, quad_size = { 20, 20 })
      draw_lots_of_quads(50, { 700, 20 }, colored = true, quad_size = { 100, 100 })
      draw_lots_of_quads(500, { 20, 550 }, quad_size = { 5, 5 })
      draw_lots_of_quads(1000, { 400, 550 }, colored = true, quad_size = { 5, 5 })

      scissor_a := renderer.Scissor{
        min = { 20, 350 },
        max = { 250, 550 },
      }
      scissor_b := renderer.Scissor{
        min = { 200, 200 },
        max = { 400, 400 },
      }

      draw_lots_of_quads(50, { 20, 350 }, colored = true, scissor = scissor_a)
      draw_lots_of_quads(50, { 270, 350 }, colored = true, scissor = scissor_b)
      draw_lots_of_quads(20, { 520, 350 }, scissor = scissor_a)
      draw_lots_of_quads(20, { 520, 350 }, scissor = scissor_b)
      draw_lots_of_quads(20, { 520, 350 }, scissor = scissor_a)
      draw_lots_of_quads(20, { 520, 350 }, scissor = scissor_b)

      // print stats
      stats: renderer.Stats
      renderer.stats_fill(&stats)
      fmt.println(stats)
    }
  },

  .Targets = {
    init = proc() -> bool {
      if !renderer.target_init(&game.scene_target_extra_target, {200, 200}) {
        return true
      }
      
      return true
    },

    render = proc() {

      {
        temp_draw_commands: renderer.Draw_Commands
        renderer.draw_commands_init(&temp_draw_commands, context.temp_allocator)

        renderer.render_quad(
          &temp_draw_commands,
          min = { 100, 100 },
          max = { 200, 200 },
          tint = ORANGE,
        )

        renderer.draw_commands_submit(&temp_draw_commands, game.scene_target_extra_target)
      }

      renderer.render_quad(
        &game.draw_commands,
        min = { 0, 0},
        max = ([2]f32)(scenes[.Targets].target.size),
        tint = WHITE,
        texture_handle = game.scene_target_extra_target.target,
      )

    },
  },

  .Lines = {
    init = proc() -> bool {
      return true
    },

    render = proc() {

      renderer.debug_render_line(&game.draw_commands,
        { 700, 100 }, { 200, 700 }, ORANGE)
      renderer.debug_render_arrow(&game.draw_commands,
        { 50, 500 }, { 700, 900 }, ORANGE)

      renderer.debug_render_arrow(&game.draw_commands,
        { 100, 100 }, { 500, 100 }, RED);
      renderer.debug_render_arrow(&game.draw_commands,
        { 500, 200 }, { 100, 200 }, BLUE);
      renderer.debug_render_arrow(&game.draw_commands,
        { 300, 100 }, { 300, 500 }, GREEN);
      renderer.debug_render_arrow(&game.draw_commands,
        { 400, 500 }, { 400, 100 }, YELLOW);
      renderer.debug_render_arrow(&game.draw_commands,
        { 100, 500 }, { 400, 200 }, PURPLE);
      renderer.debug_render_arrow(&game.draw_commands,
        { 500, 100 }, { 200, 400 }, PINK);
      renderer.debug_render_arrow(&game.draw_commands,
        { 600, 600 }, { 650, 650 }, WHITE);
      renderer.debug_render_arrow(&game.draw_commands,
        { 50, 700 }, { 900, 300 }, ORANGE);
      renderer.debug_render_arrow(&game.draw_commands,
        { 300, 300 }, { 300, 300 }, GRAY);

    },
  },
}

RED :: [4]f32 { 1, 0, 0, 1 }
ORANGE :: [4]f32 { 1, 0.5, 0, 1 }
YELLOW :: [4]f32 { 1, 1, 0, 1 }
GREEN :: [4]f32 { 0, 1, 0, 1 }
BLUE :: [4]f32 { 0, 0, 1, 1 }
PURPLE :: [4]f32 { 0.5, 0, 0.5, 1 }
PINK :: [4]f32 { 1, 0.4, 0.7, 1 }
CYAN :: [4]f32 { 0, 1, 1, 1 }
MAGENTA :: [4]f32 { 1, 0, 1, 1 }
WHITE :: [4]f32 { 1, 1, 1, 1 }
BLACK :: [4]f32 { 0, 0, 0, 1 }
GRAY :: [4]f32 { 0.5, 0.5, 0.5, 1 }
BROWN :: [4]f32 { 0.6, 0.3, 0.1, 1 }
LIME :: [4]f32 { 0.5, 1, 0, 1 }
TEAL :: [4]f32 { 0, 0.5, 0.5, 1 }
NAVY :: [4]f32 { 0, 0, 0.5, 1 }
MAROON :: [4]f32 { 0.5, 0, 0, 1 }
GOLD :: [4]f32 { 1, 0.84, 0, 1 }
CORAL :: [4]f32 { 1, 0.5, 0.31, 1 }
TURQUOISE :: [4]f32 { 0.25, 0.88, 0.82, 1 }
INDIGO :: [4]f32 { 0.29, 0, 0.51, 1 }

COLORS := [][4]f32 {
    RED,
    ORANGE,
    YELLOW,
    GREEN,
    BLUE,
    PURPLE,
    PINK,
    CYAN,
    MAGENTA,
    WHITE,
    BLACK,
    GRAY,
    BROWN,
    LIME,
    TEAL,
    NAVY,
    MAROON,
    GOLD,
    CORAL,
    TURQUOISE,
    INDIGO,
}
