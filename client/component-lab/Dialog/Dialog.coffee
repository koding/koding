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
    height
    subtitle
    message
    buttonType
    buttonTitle
    onButtonClick
    secondaryButtonType
    secondaryButtonTitle
    onSecondaryButtonClick
    secondaryContent
  } = props

  modalProps =
    isOpen: isOpen
    showAlien: showAlien
    shouldCloseOnOverlayClick: no
    width: 'medium'
    height: height or 'short'

  titleClassName = "#{styles.title} #{styles[type]}"

  <Modal {...modalProps}>
    <Modal.Content>
      <div className={titleClassName}>{title}</div>
      <div className={styles.subtitle}>{subtitle}</div>
      <div className={styles.message}>{message}</div>
      {buttonTitle and
        <Action
          type={buttonType}
          title={buttonTitle}
          onClick={onButtonClick} /> }
      {secondaryButtonTitle and
        <Action
          type={secondaryButtonType}
          title={secondaryButtonTitle}
          onClick={onSecondaryButtonClick} /> }
      {secondaryContent and
        <div className={styles.secondaryContent}>
          {secondaryContent}
        </div>}
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

Action = ({ type, onClick, title }) ->

  action = if type is 'link'
    <a href="#" onClick={onClick}>{title}</a>
  else
    <Button type={type} auto={on} onClick={onClick}>
      {title}
    </Button>

  <div className={styles.action}>{action}</div>
