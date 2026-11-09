package main

import "base:intrinsics"
import "core:os"
import "core:log"
import "khasix:serializer"

Entity_ID :: enum {
  Player,
  Monster,
  Item,
}

Physics_Kind :: enum {
  Static,
  Kinematic,
}

Flag :: enum {
  Draw_Shadow,
  Following,
  On_Fire,
}

Flags :: bit_set[Flag; i64]

Entity :: struct {
  id:   Entity_ID,
  name: string,
  flags: Flags,
  phys_kind: Physics_Kind,
  pos: [2]f32,
  bullets: int,
  rotation: quaternion128,
  slice_a: []f32,
}

main :: proc() {
  logger := log.create_console_logger()
  defer log.destroy_console_logger(logger)
  context.logger = logger

  w: serializer.Dyn_Buffer_Writer
  serializer.dyn_buffer_writer_init(&w, context.allocator)

  serialize_entity(&w, &e1)
  serialize_entity(&w, &e2)
  serialize_entity(&w, &e3)

  r: serializer.Buffer_Reader
  serializer.buffer_reader_init(&r, w.buffer[:], context.allocator)

  {
    re1, re2, re3: Entity

    serialize_entity(&r, &re1)
    serialize_entity(&r, &re2)
    serialize_entity(&r, &re3)

  }
}

serialize_entity :: proc(s: ^$S, e: ^Entity) -> bool {
  serializer.serialize_enum(s, &e.id) or_return
  serializer.serialize_string(s, &e.name) or_return
  serializer.serialize_bitset(s, &e.flags) or_return
  serializer.serialize_enum(s, &e.phys_kind) or_return
  serializer.serialize_vector(s, &e.pos) or_return
  serializer.serialize_int(s, &e.bullets) or_return
  serializer.serialize_quat(s, &e.rotation) or_return
  serializer.serialize_slice_opaque(s, &e.slice_a) or_return
  return true
}

e1 := Entity {
  id = .Player,
  name = "John",
  phys_kind = .Kinematic,
  pos = { 100, 200 },
  bullets = 300,
  rotation = quaternion(w = 1, x = 2, y = 3, z = 4),
  flags = { .Draw_Shadow, .On_Fire },
}

e2 := Entity {
  id = .Monster,
  name = "Skeleton",
  phys_kind = .Kinematic,
  pos = { 0, 50 },
  bullets = 20,
  flags = { .On_Fire },
  slice_a = { 1.0, 2.4, 34.5, 8.4 },
}

e3 := Entity {
  id = .Item,
  name = "Magic Bow",
  phys_kind = .Static,
  pos = { 1000, 900 },
  bullets = 0,
  flags = { .Draw_Shadow },
}
