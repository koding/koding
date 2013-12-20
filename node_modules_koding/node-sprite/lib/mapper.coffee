class Mapper
  height: 0
  width: 0
  constructor: (@padding) ->
  area: -> @width * @height

class VerticalMapper extends Mapper
  map: (images) ->
    @width = @height = 0

    for image in images
      image.positionX = 0
      image.positionY = @height
      @height += image.height + @padding
      @width = image.width if image.width > @width
      
    @height -= @padding

class HorizontalMapper extends Mapper
  map: (images) ->
    @width = @height = 0

    for image in images
      image.positionX = @width
      image.positionY = 0
      @width += image.width + @padding
      @height = image.height if image.height > @height

    @width -= @padding


module.exports.VerticalMapper = VerticalMapper
module.exports.HorizontalMapper = HorizontalMapper