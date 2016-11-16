React = require('react')
ReactDOM = require('react-dom')
Helpers = require('./helpers')

styles = require './Notification.stylus'

whichTransitionEvent = ->

  el = document.createElement('fakeelement')
  transition = null
  transitions =
    transition : 'transitionend'
    OTransition : 'oTransitionEnd'
    MozTransition : 'transitionend'
    WebkitTransition : 'webkitTransitionEnd'
  Object.keys(transitions).forEach (transitionKey) ->
    if el.style[transitionKey] isnt undefined
      transition = transitions[transitionKey]
    return
  transition


module.exports = NotificationView = React.createClass

    propTypes :
      notification : React.PropTypes.object
      onRemove : React.PropTypes.func

    getDefaultProps: ->

      {
        onRemove: ->
      }


    getInitialState: ->

      {
        visible : false
        removed : false
      }


    componentWillMount: ->

      @_noAnimation = @props.noAnimation
      return


    _notificationTimer : null
    _isMounted : false
    _noAnimation : null
    _removeCount : 0


    _hideNotification: ->

      if @_notificationTimer
        @_notificationTimer.clear()
      if @_isMounted
        @setState
          visible : false
          removed : true
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
      element = ReactDOM.findDOMNode(this)
      notification = @props.notification
      @_isMounted = true
      if not @_noAnimation
        if transitionEvent
          element.addEventListener transitionEvent, @_onTransitionEnd
        else
          @_noAnimation = true
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
      @_isMounted = false
      return


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
      closeButton = null
      actions = null
      actionsClass = null
      primaryButton = null
      secondaryButton = null
      message = notification.content
      if @state.visible
        className.push styles.kd_notification_visible
      else
        className.push styles.kd_notification_hidden
      if notification.dismissible
        className.push styles.kd_notification_dismissible
        closeButton = <button className={styles.kd_notification_close} onClick={this._dismiss}>&times;</button>
      if notification.primaryButtonTitle
        primaryButton = <div className={styles.kd_notification_action}>
            <button type="button"
                    className={[
                      styles.kd_notification_button
                      styles.kd_notification_button_primary
                    ].join ' '}
                    onClick={this._handlePrimaryButtonClick}>
                {notification.primaryButtonTitle}
            </button>
          </div>
      if notification.secondaryButtonTitle
        secondaryButton = <div className={styles.kd_notification_action}>
            <button type="button"
                    className={[
                      styles.kd_notification_button
                      styles.kd_notification_button_secondary
                    ].join ' '}
                    onClick={this._handleSecondaryButtonClick}>
                {notification.secondaryButtonTitle}
            </button>
          </div>
      if notification.primaryButtonTitle or notification.secondaryButtonTitle
        closeButton = null
        className = className.filter (word) -> word isnt styles.kd_notification_dismissible
        actionsClass = if not notification.secondaryButtonTitle then styles.kd_notification_single_action else styles.kd_notification_multiple_actions
        actions = <div className={styles.kd_notification_actions}>
            <div className={actionsClass}>
              {primaryButton}
              {secondaryButton}
            </div>
          </div>
      <div className={className.join ' '} onClick={this._dismiss} onMouseEnter={ this._handleMouseEnter }
        onMouseLeave={this._handleMouseLeave}>
        <div className={styles.kd_notification_level}>
          <i className={iconClass.join ' '}></i>
        </div>
          <div className={styles.kd_notification_content}>
            {message}
          </div>
        {closeButton}
        {actions}
      </div>
