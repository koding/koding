kd       = require 'kd'
React    = require 'kd-react'
ReactDOM = require 'react-dom'

module.exports = class ReactView extends kd.CustomHTMLView

  renderReact: ->

    console.error "#{@constructor.name}: needs to implement 'renderReact' method"

    return null


  viewAppended: ->

    ReactDOM.render(
      @renderReact()
      @getElement()
    )
