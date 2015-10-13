kd     = require 'kd'
React  = require 'kd-react'
Portal = require 'react-portal'
isNodeInRoot = require 'app/util/isnodeinroot'


class ModalOverlay extends React.Component

  @defaultProps =
    onClick: kd.noop

  render: ->
    <div className="ModalOverlay" onClick={@props.onClick} />


module.exports = class Modal extends React.Component

  @defaultProps =
    onClose             : kd.noop
    closeOnEsc          : yes
    hasOverlay          : yes
    isOpen              : no
    closeIcon           : yes

  constructor: (options = {}, data) ->

    super options, data

    @handleMouseClickOutside = @handleMouseClickOutside.bind this


  getPortalProps: ->
    isOpened            : @props.isOpen
    onClose             : @props.onClose
    closeOnEsc          : @props.closeOnEsc


  componentDidMount: ->

    document.addEventListener('mousedown', @handleMouseClickOutside);


  componentWillUnmount: ->

    document.removeEventListener('mousedown', @handleMouseClickOutside);


  handleMouseClickOutside: (event) ->

    return if isNodeInRoot event.target, React.findDOMNode @refs.ModalWrapper

    return @props.handleMouseClickOutside(event)  if @props.handleMouseClickOutside

    event.stopPropagation()
    @props.onClose()


  renderModalCloseIcon: ->

    if @props.closeIcon
      <span className="close-icon closeModal" title="Close [ESC]" onClick={@bound 'closePortal'}></span>


  renderModal: ->

    return null  unless @props.isOpen

    <Portal {...@getPortalProps()} ref="modal">
      <div ref='ModalWrapper' className={kd.utils.curry 'Reactivity Modal', @props.className}>
        {@renderModalCloseIcon()}
        {@props.children}
      </div>
    </Portal>


  closePortal: -> @props.onClose?()


  renderOverlay: ->

    return null  unless @props.isOpen and @props.hasOverlay

    return \
      <Portal ref="overlay" isOpened={@props.isOpen} onClick={@bound 'closePortal'}>
        <ModalOverlay />
      </Portal>


  render: ->
    <div className="Modal-container">
      {@renderModal()}
      {@renderOverlay()}
    </div>


###
# Helper classes to be able to use semantic components (mostly for css
# classes):
#
# <Modal>
#   <Modal.Title>Hello World</Modal.Title>
#   <Modal.Content>Awesome Content</Modal.Content>
# </Modal>
###

class Modal.Title extends React.Component

  render: ->
    <h4 className="Modal-title">{@props.children}</h4>


class Modal.Content extends React.Component

  render: ->
    <div className="Modal-content">
      <p>{@props.children}</p>
    </div>


class Modal.ButtonGroup extends React.Component

  render: ->
    <div className="Modal-buttons">
      {@props.children}
    </div>


class Modal.Button extends React.Component

  render: ->
    <button
      {...@props}
      className={kd.utils.curry 'Button Modal-Button', @props.className}>
      {@props.children}
    </button>


