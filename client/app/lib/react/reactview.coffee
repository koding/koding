kd    = require 'kd'
React = require 'kd-react'

module.exports = class ReactView extends kd.CustomHTMLView

  renderReact: ->

    console.error "#{@constructor.name}: needs to implement 'renderReact' method"

    return null


  viewAppended: ->

    React.render(
      @renderReact()
      @getElement()
    )



