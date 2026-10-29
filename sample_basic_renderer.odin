package sample_basic_renderer

import platform "khasix:game_platform"
import "core:log"

main :: proc() {
  logger := log.create_console_logger()
  defer log.destroy_console_logger(logger)
  context.logger = logger

  platform_state := new(platform.State)
  defer platform.shutdown(platform_state)
  if !platform.init(platform_state, "Basic Renderer Sample", {1920, 1080}) {
    return
  }

  for !platform.window_should_close() {
    platform.update()

  }
}
