_ = require 'lodash'
kd             = require 'kd'
React          = require 'kd-react'
KDReactorMixin = require 'app/flux/base/reactormixin'
classnames     = require 'classnames'


module.exports = class ActivityAppComponent extends React.Component

  constructor: (props) ->

    super props

    @state = { content: props.content, modal: props.modal }


  getClassName: ->

    return classnames
      'ActivityAppComponent' : yes
      'is-withContent'       : @props.content
      'is-withModal'         : @props.modal


  componentWillReceiveProps: (nextProps) ->

    { content: currentContent, modal: currentModal } = @props
    { content: nextContent, modal: nextModal } = nextProps

    # next there will be a modal rendered,
    # there is already a content on the back,
    # but the route didn't inject any content;
    # then set currentContent to be rendered as content.
    if nextModal and currentContent and not nextContent
      @setState { modal: nextModal, content: currentContent }
    else
      @setState { modal: nextModal, content: nextContent }



  render: ->
    <div className={@getClassName()}>
      {@state.content}
      {@state.modal}
    </div>


