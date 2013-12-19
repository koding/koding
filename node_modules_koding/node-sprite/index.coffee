Sprite = require './lib/sprite'
mapper = require './lib/mapper'
fs = require 'fs'
Seq = require "seq"
{ EventEmitter } = require "events"

createSprite = (name, options = {}, cb = ->) ->
  options or= {}

  if typeof options is 'function'
    cb = options
    options = {}

  padding = options.padding || 2
  path = options.path || './images'

  map = new mapper.VerticalMapper padding
  sprite = new Sprite name, path, map, options.watch
  sprite.load (err) ->
    sprite.write (err) ->
      cb err, sprite
  sprite

createSprites = (options = {}, cb = ->) ->
  if typeof options is 'function'
    cb = options
    options = {}

  path = options.path || './images'

  Seq()
    .seq ->
      fs.readdir path, @
    .flatten()
    .parFilter (dir) ->
      fs.stat "#{path}/#{dir}", (err, stat) =>
        @ err, stat.isDirectory()
    .parMap (dir) ->
      createSprite dir, options, @
    .unflatten()
    .seq (sprites) ->
      result = {}
      result[s.name] = s for s in sprites
      cb null, result

stylus = (options = {}, cb = ->) ->
  stylus = require 'stylus'
  nodes = stylus.nodes
  retinaMatcher = new RegExp((options.retina || "-2x") + "$")
  result = {}
  helper = new EventEmitter()
  helper.fn = (name, image, dimensions) ->
    name = name.string
    image = image.string
    dimensions = if dimensions then dimensions.val else true
    sprite = result[name]
    throw new Error("missing sprite #{name}") if not sprite?
    item = sprite.image image
    throw new Error("missing image #{image} in sprite #{name}") if not item?

    width = item.width
    height = item.height
    positionX = item.positionX * -1
    positionY = item.positionY * -1

    if name.match(retinaMatcher)
      width = width / 2
      height = height / 2
      positionX = positionX / 2
      positionY = positionY / 2

    if dimensions
      width = new nodes.Property ["width"], "#{width}px"
      height = new nodes.Property ["height"], "#{height}px"
      @closestBlock.nodes.splice @closestBlock.index+1, 0, width, height

    httpUrl = (options.httpPath || options.path) + "/" + sprite.filename()

    new nodes.Property ["background"], "url('#{httpUrl}') #{positionX}px #{positionY}px"

  helper.dimensionsFn = (name, image) ->
    name = name.string
    image = image.string
    sprite = result[name]
    throw new Error("missing sprite #{name}") if not sprite?
    item = sprite.image image
    throw new Error("missing image #{image} in sprite #{name}") if not item?

    width = sprite._width()
    height = sprite._height()

    if name.match(retinaMatcher)
      width = width / 2
      height = height / 2

    return new nodes.Unit "#{width}px #{height}px"

  createSprites options, (err, sprites) ->
    for name, s in sprites
      s.on "update", ->
        helper.emit "update", name
    result = sprites
    cb err, helper
  helper


module.exports =
  sprite: createSprite,
  sprites: createSprites
  stylus: stylus