React = require 'react'
{ Header, Content, Footer } = Modal = require 'lab/Modal'
Label = require 'lab/Text/Label'

styles = require './SupportPlanActivationModal.stylus'

module.exports = SupportPlanActivationModal = (props) ->

  { label, price, image, isOpen, onActivateSupportPlanClick, 
    shouldCloseOnOverlayClick, onCancel, title } = props

  modalProps =
    showAlien: no
    isOpen: isOpen
    onRequstClose: onCancel
    shouldCloseOnOverlayClick: shouldCloseOnOverlayClick
    className: styles.SupportPlanActivationModal

  <Modal {...modalProps}>
    <Header title="Activate #{title}" className={styles.header} />
    <Content>
      <figure className={styles[image]} />
      <div>
        <Label size="large"><p className={styles.contentTitle}>You are about to activate {label}</p></Label>
        <Label size="medium" type="info">
          When you activate, you will get superior support. Your team will be
charged monthly flat fee of <span className={styles.price}>${price}</span> on each billing cycle in addition to
total cost. You can cancel anytime you want.
        </Label>
      </div>
    </Content>
    <Footer
      className={styles.footer}
      size="medium"
      primaryButtonTitle='Activate'
      onPrimaryButtonClick={onActivateSupportPlanClick}
      secondaryButtonTitle='Cancel'
      onSecondaryButtonClick={onCancel} />
  </Modal>
