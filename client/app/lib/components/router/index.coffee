{ Router } = require 'react-router'
{ createRoutes } = require 'react-router/lib/RouteUtils'

module.exports = class KDReactRouter extends Router

  ###*
   * Overriden to support routing with KDRouter and reactrouter together.
   *
   * @params {object} nextProps
  ###
  componentWillReceiveProps: (nextProps) ->

    nextRoutes = nextProps.routes or nextProps.children
    @routes = createRoutes nextRoutes

    @_updateState nextProps.location
