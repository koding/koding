{ Component, PropTypes } = React = require 'react'
classnames = require 'classnames'

Label = require 'lab/Text/Label'
Button = require 'lab/Button'

ReactModal = require 'react-modal'

styles = require './Modal.stylus'

noop = ->

module.exports = class Modal extends Component

  render: ->

    { isOpen, onAfterOpen, onRequestClose, children, contentLabel
      shouldCloseOnOverlayClick, width, height, showAlien } = @props

    className = classnames [
      styles.modal
      styles[width]
      styles[height]
    ]

    <ReactModal
      className={className}
      contentLabel={contentLabel}
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
  contentLabel: ''


exports.Header = Modal.Header = ({ title }) ->
  <div className={styles.header}>
    <Label size='xlarge' type="info">{title}</Label>
  </div>


exports.Content = Modal.Content = ({ children }) ->
  <div className={styles.content}>
    {children}
  </div>


exports.Footer = Modal.Footer = (props) ->
  { primaryButtonType, primaryButtonSize
    primaryButtonTitle, onPrimaryButtonClick } = props

  { secondaryButtonType, secondaryButtonSize
    secondaryButtonTitle, onSecondaryButtonClick } = props

  <div className={styles.footer}>
    <div className={styles.footerContainer}>

      <Button
        disabled={props.disabled}
        type={secondaryButtonType}
        size={primaryButtonSize}
        onClick={onSecondaryButtonClick}
        children={secondaryButtonTitle} />

      <Button
        disabled={props.disabled}
        type={primaryButtonType}
        size={secondaryButtonSize}
        onClick={onPrimaryButtonClick}
        children={primaryButtonTitle} />

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
