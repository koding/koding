React = require 'react'
_ = require 'lodash'

KDReactComponent = require './basecomponent'

# extend React object and inject our component into it.
# from now on requires should be like below:
#
#   React = require 'app/react'
KDReact = _.assign {}, React, {
  component: KDReactComponent
}

module.exports = KDReact

