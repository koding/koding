kd       = require 'kd'
ReactDOM = require 'react-dom'

module.exports = class ReactView extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    super options, data

    @on 'KDObjectWillBeDestroyed', =>
      ReactDOM.unmountComponentAtNode @getElement()


  renderReact: ->

    console.error "#{@constructor.name}: needs to implement 'renderReact' method"

    return null


  viewAppended: ->

    ReactDOM.render(
      @renderReact()
      @getElement()
    )

