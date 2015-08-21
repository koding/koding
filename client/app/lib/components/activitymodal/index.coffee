kd     = require 'kd'
React  = require 'kd-react'
Portal = require 'react-portal'

noop = ->


class ModalOverlay extends React.Component

  render: ->
    <div className="ModalOverlay" />


module.exports = class ActivityModal extends React.Component

  @defaultProps =
    onClose             : noop
    closeOnEsc          : yes
    closeOnOutsideClick : yes
    hasOverlay          : yes
    isOpen              : no
    className           : ''
    buttonAbortTitle    : 'CANCEL'

  onClose: (args...) -> @props.onClose? args...


  getPortalProps: ->
    isOpened            : @props.isOpen
    onClose             : @bound 'onClose'
    closeOnEsc          : @props.closeOnEsc
    closeOnOutsideClick : @props.closeOnOutsideClick


  renderModal: ->

    return null  unless @props.isOpen

    portalProps = @getPortalProps()

    return (
      <Portal {...portalProps}>
        <div className={kd.utils.curry 'Reactivity Modal', @props.className}>
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


  renderOverlay: ->
    return null  unless @props.isOpen and @props.hasOverlay

    return (
      <Portal isOpened={@props.isOpen}>
        <ModalOverlay />
      </Portal>
    )


  render: ->
    <div className="ActivityPromptModal-container">
      {@renderOverlay()}
      {@renderModal()}
    </div>


