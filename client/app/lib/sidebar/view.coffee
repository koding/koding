kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

connectCompute = require 'app/providers/connectcompute'

Container = require './container'

ConnectedContainer = connectCompute({
  storage: ['stacks', 'templates', 'machines']
})(Container)

module.exports = class SidebarView extends ReactView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'Sidebar-ReactView'

    super options, data


  renderReact: ->

    <ConnectedContainer />
