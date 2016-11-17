_ = require 'lodash'
React = require('react')
ReactDOM = require('react-dom')
kd = require ('kd')

Button = require '../Button/Button'
Box = require '../Box/Box'

styles = require './Notification.stylus'
Helpers = require('./helpers')
Constants = require './constants'

whichTransitionEvent = ->

  el = document.createElement('fakeelement')
  transition = null
  transitions =
    transition : 'transitionend'
    OTransition : 'oTransitionEnd'
    MozTransition : 'transitionend'
    WebkitTransition : 'webkitTransitionEnd'
  _.keys(transitions).forEach (transitionKey) ->
    if el.style[transitionKey] isnt undefined
      transition = transitions[transitionKey]
    return
  transition


module.exports = class NotificationView extends React.Component

    constructor: (props) ->

      super props
      @_style = { zIndex: 100 - @props.index};
      @_notificationTimer = null
      @_isMounted = no
      @_noAnimation = no
      @_removeCount = 0
      @state =
        visible : no
        removed : no
      @_hideNotification = @_hideNotification.bind this
      @_removeNotification = @_removeNotification.bind this
      @_dismiss = @_dismiss.bind this
      @_showNotification = @_showNotification.bind this
      @_onTransitionEnd = @_onTransitionEnd.bind this
      @_handleMouseEnter = @_handleMouseEnter.bind this
      @_handleMouseLeave = @_handleMouseLeave.bind this
      @_handlePrimaryButtonClick = @_handlePrimaryButtonClick.bind this
      @_handleSecondaryButtonClick = @_handleSecondaryButtonClick.bind this


    componentWillMount: ->

      @_noAnimation = @props.noAnimation


    _hideNotification: ->

      if @_notificationTimer
        @_notificationTimer.clear()
      if @_isMounted
        @setState
          visible : no
          removed : yes
      if @_noAnimation
        @_removeNotification()
      return


    _removeNotification: ->

      @props.onRemove(@props.notification.uid)
      return


    _dismiss: ->

      if not @props.notification.dismissible
        return
      @_hideNotification()
      return


    _showNotification: ->

      self = this
      setTimeout (->
        if self._isMounted
          self.setState visible : true
        return
      ), 50
      return


    _onTransitionEnd: ->

      if @_removeCount > 0
        return
      if @state.removed
        @_removeCount++
        @_removeNotification()
      return


    componentDidMount: ->

      self = this
      transitionEvent = whichTransitionEvent()
      element = ReactDOM.findDOMNode(self)
      notification = @props.notification
      @_isMounted = yes
      if not @_noAnimation
        if transitionEvent
          element.addEventListener transitionEvent, @_onTransitionEnd
        else
          @_noAnimation = yes
      if not notification.dismissible and not notification.primaryButtonTitle and not notification.secondaryButtonTitle
        @_notificationTimer = new (Helpers.Timer)((->
          self._hideNotification()
          return
        ), notification.duration)
      @_showNotification()
      return


    _handleMouseEnter: ->

      notification = @props.notification
      if not notification.dismissible and not notification.primaryButtonTitle and not notification.secondaryButtonTitle
        @_notificationTimer.pause()
      return


    _handleMouseLeave: ->

      notification = @props.notification
      if not notification.dismissible and not notification.primaryButtonTitle and not notification.secondaryButtonTitle
        @_notificationTimer.resume()
      return


    _handlePrimaryButtonClick: (event) ->

      event.preventDefault()
      notification = @props.notification
      @_hideNotification()
      if typeof notification.onPrimaryButtonClick is 'function'
        notification.onPrimaryButtonClick()
      return


    _handleSecondaryButtonClick: (event) ->

      event.preventDefault()
      notification = @props.notification
      @_hideNotification()
      if typeof notification.onSecondaryButtonClick is 'function'
        notification.onSecondaryButtonClick()
      return


    componentWillUnmount: ->

      element = ReactDOM.findDOMNode(this)
      transitionEvent = whichTransitionEvent()
      element.removeEventListener transitionEvent, @_onTransitionEnd
      @_isMounted = no


    render: ->

      notification = @props.notification
      className = [
        styles.kd_notification
        styles["kd_notification_#{notification.type}"]
      ]
      iconClass = [
        styles.kd_notification_icon
        styles["kd_notification_icon_#{notification.type}"]
      ]
      message = notification.content
      if @state.visible
        className.push styles.kd_notification_visible
      else
        className.push styles.kd_notification_hidden
      if notification.dismissible
        className.push styles.kd_notification_dismissible
      if notification.primaryButtonTitle or notification.secondaryButtonTitle
        className = className.filter (word) -> word isnt styles.kd_notification_dismissible
      <div
        className={className.join ' '}
        style={@_style}
        onMouseEnter={ @_handleMouseEnter }
        onMouseLeave={@_handleMouseLeave}>
        <Box className={styles.kd_notification_level}>
          <i className={iconClass.join ' '}></i>
        </Box>
        <div className={styles.kd_notification_content}>
          {message}
        </div>
        {
          if notification.dismissible
            <CloseButton onClick={@_dismiss} />
        }
        {
          if notification.primaryButtonTitle or notification.secondaryButtonTitle
            <Actions
              notification={notification}
              onPrimaryButtonClick={@_handlePrimaryButtonClick}
              onSecondaryButtonClick={@_handleSecondaryButtonClick} />
        }
      </div>

    @propTypes :
      notification : React.PropTypes.object
      onRemove : React.PropTypes.func

    @defaultProps =
      onRemove: kd.noop


CloseButton = ({onClick}) ->

  <button
    className={styles.kd_notification_close}
    onClick={onClick}>
      &times;
  </button>


ActionButton = ({type, title, onClick}) ->

  <div className={styles.kd_notification_action}>
    <Button
      type={type}
      size="medium"
      onClick={onClick}>
      {title}
    </Button>
  </div>


Actions = ({notification, onPrimaryButtonClick, onSecondaryButtonClick}) ->

  actionsClass = if not notification.secondaryButtonTitle then styles.kd_notification_single_action else styles.kd_notification_multiple_actions
  <div className={styles.kd_notification_actions}>
    <div className={actionsClass}>
      {
        if notification.primaryButtonTitle
          <ActionButton
            type={'link-'+Constants.types[notification.type]}
            title={notification.primaryButtonTitle}
            onClick={onPrimaryButtonClick} />
      }
      {
        if notification.secondaryButtonTitle
          <ActionButton
            type="link-secondary"
            title={notification.secondaryButtonTitle}
            onClick={onSecondaryButtonClick} />
      }
    </div>
  </div>
