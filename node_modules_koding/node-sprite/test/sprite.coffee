Sprite = require '../lib/sprite'
Image = require '../lib/image'
VerticalMapper = require('../lib/mapper').VerticalMapper
HorizontalMapper = require('../lib/mapper').HorizontalMapper

path = './test/images'

mapper = new VerticalMapper(10)

module.exports =
  testSpriteLoading: (beforeExit, assert) ->
    sprite = new Sprite 'global', path, mapper
    sprite.load ->
      assert.equal 2, sprite.images.length
  testWritingOutput: (beforeExit, assert) ->
    sprite = new Sprite 'global', path, mapper
    sprite.load ->
      sprite.write ->
        assert.ok true
  testImageInfo: (beforeExit, assert) ->
    sprite = new Sprite 'global', path, mapper
    sprite.load ->
      assert.equal 100, sprite.image('100x300').width
      assert.equal 300, sprite.image('100x300').height
      assert.equal 0, sprite.image('200x200').positionX
      assert.equal 310, sprite.image('200x200').positionY
      assert.isUndefined sprite.image('350x151')
  testImageChecksums: (beforeExit, assert) ->
    sprite = new Sprite 'global', path, mapper
    sprite.load ->
      assert.equal 32, sprite.checksum().length