kd     = require 'kd'
React  = require 'kd-react'
Portal = require 'react-portal'

noop = ->


class ModalOverlay extends React.Component

  render: ->
    <div className="ModalOverlay" />


module.exports = class ActivityPromptModal extends React.Component

module.exports = class ActivityPromptModal extends ActivityModal

  renderModal: ->

    return null  unless @props.isOpen

    portalProps = @getPortalProps()

    return (
      <Portal {...portalProps}>
        <div className={kd.utils.curry 'Reactivity Modal ActivityPromptModal', @props.className}>
          <h4 className="Modal-title">{@props.title}</h4>
          <div className="Modal-content">
            <p>{@props.children}</p>
          </div>
          <div className="Modal-buttons">
            <button className="Button Modal-Button Button--danger" onClick={@props.onConfirm}>
              {@props.buttonConfirmTitle}
            </button>
            <button className="Button Modal-Button Button--secondary" onClick={@props.onAbort}>
              {@props.buttonAbortTitle}
            </button>
          </div>
        </div>
      </Portal>
    )

