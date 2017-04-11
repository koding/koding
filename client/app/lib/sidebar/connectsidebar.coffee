React = require 'app/react'
kd = require 'kd'

debug = require('debug')('sidebar:connect')

module.exports = connectSidebar = (config) -> (WrappedComponent) ->

  class ConnectSidebar extends React.Component

    constructor: (props) ->

      super props

      { sidebar } = kd.singletons

      @_mounted = no
      @_subscription = null


    transformSidebarState: (sidebarState) ->

      return  unless @_mounted

      @setState (config.transformState sidebarState, @props) or {}


    componentDidMount: ->

      { sidebar } = kd.singletons

      @_mounted = yes
      @_subscription = sidebar.subscribeChange @bound 'transformSidebarState'

      @setState (sidebar.getState @bound 'transformSidebarState') or {}


    componentWillReceiveProps: (nextProps) ->

      { sidebar } = kd.singletons

      @setState (config.transformState sidebar.getState(), nextProps) or {}


    componentWillUnmount: ->

      @_subscription?.cancel()
      @_subscription = null
      @_mounted = no


    render: ->
      <WrappedComponent {...@state} {...@props} />


  name = \
    WrappedComponent.displayName or WrappedComponent.name or 'Component'

  ConnectSidebar.displayName = "ConnectSidebar(#{name})"

  return ConnectSidebar
