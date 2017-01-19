{ merge } = require 'lodash'
kd       = require 'kd'
ReactDOM = require 'react-dom'

module.exports = class ReactView extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    super options, data

    @on 'KDObjectWillBeDestroyed', =>
      ReactDOM.unmountComponentAtNode @getElement()


  updateOptions: (newOptions) ->
    @options = merge {}, @options, newOptions
    @viewAppended()


  renderReact: ->

    console.error "#{@constructor.name}: needs to implement 'renderReact' method"

    return null


  viewAppended: ->
    kd.singletons.mainView.ready =>
      ReactDOM.render(
        @renderReact()
        @getElement()
      )
