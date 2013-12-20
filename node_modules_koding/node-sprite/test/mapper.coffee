Sprite = require '../lib/sprite'
VerticalMapper = require('../lib/mapper').VerticalMapper
HorizontalMapper = require('../lib/mapper').HorizontalMapper

path = './test/images'

module.exports =
  testVerticalMapper: (beforeExit, assert) ->
    mapper = new VerticalMapper(10)
    sprite = new Sprite 'global', path, mapper
    sprite.load ->
      images = sprite.images
      mapper.map images

      # checking y positions
      assert.equal 0, images[0].positionY
      assert.equal 310, images[1].positionY

      # checking x positions
      assert.equal 0, image.positionX for image in images

      # checking sprite dimensions
      assert.equal 200, mapper.width
      assert.equal 510, mapper.height

      # checking area
      assert.equal 200*510, mapper.area()

  testHorizontalMapper: (beforeExit, assert) ->
    mapper = new HorizontalMapper(10)
    sprite = new Sprite 'global', path, mapper
    sprite.load ->
      images = sprite.images
      mapper.map images

      # checking y positions
      assert.equal 0, images[0].positionX
      assert.equal 110, images[1].positionX

      # checking x positions
      assert.equal 0, image.positionY for image in images

      # checking sprite dimensions
      assert.equal 310, mapper.width
      assert.equal 300, mapper.height

      # checking area
      assert.equal 310*300, mapper.area()