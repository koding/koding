{ Component, PropTypes } = React = require 'react'
classnames = require 'classnames'

Label = require 'lab/Text/Label'
Button = require 'lab/Button'

ReactModal = require 'react-modal'

styles = require './Modal.stylus'

noop = ->

module.exports = class Modal extends Component

  render: ->

    { isOpen, onAfterOpen, onRequestClose, children,
      shouldCloseOnOverlayClick, width, height, showAlien, className } = @props

    className = classnames [
      styles.modal
      styles[width]
      styles[height]
      className
    ].join ' '
    <ReactModal
      className={className}
      overlayClassName={styles.overlay}
      isOpen={isOpen}
      onAfterOpen={onAfterOpen}
      onRequestClose={onRequestClose}
      shouldCloseOnOverlayClick={shouldCloseOnOverlayClick}>
      <div className={styles.wrapper}>
        {<figure className={styles.alien}/>  if showAlien}
        {children}
      </div>
    </ReactModal>


Modal.defaultProps =
  width: 'large'
  height: 'normal'
  showAlien: no


exports.Header = Modal.Header = ({ title, className }) ->
  className = [
    styles.header
    className
  ].join ' '
  <div className={className}>
    <Label type="info">{title}</Label>
  </div>


exports.Content = Modal.Content = ({ children }) ->
  <div className={styles.content}>
    {children}
  </div>


exports.Footer = Modal.Footer = (props) ->
  { primaryButtonType, primaryButtonTitle, onPrimaryButtonClick,
    secondaryButtonType, secondaryButtonTitle, onSecondaryButtonClick, className, size } = props
  className = [
    styles.footer
    className
  ].join ' '
  <div className={className}>
    <div className={styles.footerContainer}>
      <Button type={secondaryButtonType} size={'small' if not size} onClick={onSecondaryButtonClick}>
        {secondaryButtonTitle}
      </Button>
      <Button type={primaryButtonType} size={'small' if not size} onClick={onPrimaryButtonClick}>
        {primaryButtonTitle}
      </Button>

    </div>
  </div>

Modal.Footer.defaultProps =
  primaryButtonType: 'primary-1'
  secondaryButtonType: 'secondary'
  primaryButtonSize: 'small'
  secondaryButtonSize: 'small'
  primaryButtonTitle: 'Primary'
  secondaryButtonTitle: 'Secondary'
  onPrimaryButtonClick: noop
  onSecondaryButtonClick: noop
