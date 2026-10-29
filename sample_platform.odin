package sample_platform

import platform "khasix:game_platform"
import "core:log"

main :: proc() {
  logger := log.create_console_logger()
  defer log.destroy_console_logger(logger)
  context.logger = logger

  platform_state := new(platform.State)
  defer platform.shutdown(platform_state)
  if !platform.init(platform_state, "Khasix Platform Sample", {1920, 1080}) {
    return
  }

	log_mouse_position := false

  for !platform.window_should_close() {
    platform.update()

    for button in platform.Button {
      if platform.button_pressed(button) {
        log.infof("%v pressed", button)
      }
    }

		if platform.button_pressed(.M) {
			log_mouse_position = !log_mouse_position
		}

		if log_mouse_position {
			log.infof("Mouse Pos: %v", platform.mouse_position())
		}

  }
}
