_ = require 'lodash'
kd             = require 'kd'
React          = require 'kd-react'
KDReactorMixin = require 'app/flux/base/reactormixin'
classnames     = require 'classnames'


module.exports = class ActivityAppComponent extends React.Component

  getClassName: ->

    return classnames
      'ActivityAppComponent' : yes
      'is-withContent'       : @props.children.content
      'is-withModal'         : @props.children.modal


  render: ->
    <div className={@getClassName()}>
      {@props.children.content}
      {@props.children.modal}
    </div>


