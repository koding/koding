_ = require 'lodash'
kd             = require 'kd'
React          = require 'kd-react'
KDReactorMixin = require 'app/flux/base/reactormixin'
classnames     = require 'classnames'


module.exports = class ActivityAppComponent extends React.Component

  getClassName: ->

    return classnames
      'ActivityAppComponent' : yes
      'is-withContent'       : @props.content
      'is-withModal'         : @props.modal


  render: ->
    <div className={@getClassName()}>
      {@props.content}
      {@props.modal}
    </div>


