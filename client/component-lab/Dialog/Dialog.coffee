React = require 'react'
classnames = require 'classnames'

Modal = require 'lab/Modal'
Label = require 'lab/Text/Label'
Button = require 'lab/Button'

styles = require './Dialog.stylus'

module.exports = Dialog = (props) ->
  { isOpen
    showAlien
    type
    title
    subtitle
    message
    buttonType
    buttonTitle
    onButtonClick } = props

  modalProps =
    isOpen: isOpen
    showAlien: showAlien
    shouldCloseOnOverlayClick: no
    width: 'medium'
    height: 'short'

  titleClassName = "#{styles.title} #{styles[type]}"

  action = if buttonType is 'link'
    <a href="#" onClick={onButtonClick}>{buttonTitle}</a>
  else
    <Button type={buttonType} auto={on} onClick={onButtonClick}>
      {buttonTitle}
    </Button>


  <Modal {...modalProps}>
    <Modal.Content>
      <div className={titleClassName}>{title}</div>
      <div className={styles.subtitle}>{subtitle}</div>
      <div className={styles.message}>{message}</div>
      <div className={styles.action}>{action}</div>
    </Modal.Content>
  </Modal>

Dialog.defaultProps =
  type: 'success'
  title: 'Title'
  subtitle: 'The description goes into subtitle'
  message: 'Imagine a long text here'
  buttonType: 'primary-1'
  buttonTitle: 'Button Title'
  onButtonClick: ->


