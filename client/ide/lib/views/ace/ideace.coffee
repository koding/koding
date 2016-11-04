kd  = require 'kd'
Ace = require 'ace/ace'


module.exports = class IDEAce extends Ace


  setHeight: (height) ->

    if @descriptionView?.getHeight
      height -= @descriptionView.getHeight()

    super height
