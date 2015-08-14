React = require 'kd-react'
ReactView = require 'app/react/reactview'
SidebarSections = require './index'


module.exports = class SidebarSectionsView extends ReactView

  renderReact: ->
    <SidebarSections />
