kd               = require 'kd'
KDView           = kd.View
KDCustomHTMLView = kd.CustomHTMLView


# ported from http://jsfiddle.net/Aapn8/3410/
module.exports = class CircularProgressBar extends KDView

  constructor: (options = {}, data) ->

    options.cssClass             = kd.utils.curry 'circular-progress-bar', options.cssClass
    options.size                ?= 220
    options.percent             ?= 42
    options.lineWidth           ?= 15
    options.rotate              ?= 0
    options.showPercentageText  ?= yes
    options.baseColor          or= '#EAEAEA'
    options.percentColor       or= '#F8AB1C'
    options.strokeCap          or= 'square' # round or square

    super options, data

    @createCanvas()
    @createPercentage()
    @draw()


  createCanvas: ->

    { size } = @getOptions()

    @addSubView @canvas = new KDCustomHTMLView
      tagName    : 'canvas'
      attributes :
        width    : size
        height   : size


  createPercentage: ->

    @addSubView @text = new KDCustomHTMLView
      tagName   : 'span'
      cssClass  : 'percentage'
      partial   : "#{@getOptions().percent}%"


  draw: ->

    { size, lineWidth, rotate, percent, baseColor, percentColor } = @getOptions()

    @ctx    = @canvas.getElement().getContext '2d'
    radius  = (size - lineWidth) / 2

    @ctx.translate size / 2, size / 2 # change center
    @ctx.rotate (-1 / 2 + rotate / 180) * Math.PI  # rotate -90 deg

    @drawCircle baseColor, 100
    @drawCircle percentColor, percent / 100


  drawCircle: (color, percent) ->

    { size, lineWidth, strokeCap } = @getOptions()

    percent = Math.min Math.max(0, percent || 1), 1
    radius  = (size - lineWidth) / 2

    @ctx.beginPath()
    @ctx.arc(0, 0, radius, 0, Math.PI * 2 * percent, false)

    @ctx.strokeStyle = color
    @ctx.lineCap     = strokeCap
    @ctx.lineWidth   = lineWidth

    @ctx.stroke()
