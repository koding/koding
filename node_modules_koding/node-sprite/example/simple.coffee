sprite = require '../'

sprite.sprite 'global', {path: './images', padding: 2}, (err, s) ->
  console.log "created sprite from #{s.images.length} images"
  i = s.image '50 100'
  console.log "image '50 100' with dimensions #{i.width}x#{i.height} is at position #{i.positionX},#{i.positionY}"