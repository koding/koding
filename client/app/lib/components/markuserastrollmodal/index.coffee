kd            = require 'kd'
React         = require 'kd-react'
Portal        = require 'react-portal'
AppFlux       = require 'app/flux'
ActivityModal = require 'app/components/activitymodal'

noop = ->

class ModalOverlay extends React.Component

  render: ->
    <div className="ModalOverlay" />

module.exports = class MarkUserAsTrollModal extends ActivityModal


  markUserAsTroll: ->

    AppFlux.actions.user.markUserAsTroll @props.account
    @props.onClose()


  renderModal: ->

    return null  unless @props.isOpen

    portalProps = @getPortalProps()

    return (
      <Portal {...portalProps}>
        <div className={kd.utils.curry 'Reactivity Modal MarkUserAsTrollModal', @props.className}>
          <h4 className="Modal-title">MARK USER AS TROLL</h4>
          <div className="Modal-content">
            <p>
              This is what we call 'Trolling the troll' mode.<br/><br/>
              All of the troll's activity will disappear from the feeds, but the troll himself will think that people still gets his posts/comments. <br/><br/>
              Are you sure you want to mark him as a troll?
            </p>
          </div>
          <div className="Modal-buttons">
            <button className="Button Modal-Button Button--danger" onClick={@bound 'markUserAsTroll'}>
              YES, THIS USER IS DEFINITELY A TROLL
            </button>
            <button className="Button Modal-Button Button--secondary" onClick={@props.onAbort}>
              CANCEL
            </button>
          </div>
        </div>
      </Portal>
    )
