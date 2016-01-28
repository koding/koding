kd        = require 'kd'
React     = require 'kd-react'
ReactView = require 'app/react/reactview'
Sidebar   = require './index'


module.exports = class SidebarView extends ReactView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'Sidebar-ReactView', options.cssClass

    super options, data


  renderReact: ->
    <Sidebar />