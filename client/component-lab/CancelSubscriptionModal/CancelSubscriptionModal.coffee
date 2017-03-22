React = require 'react'

{ Header, Content, Footer } = Modal = require 'lab/Modal'
Label = require 'lab/Text/Label'

styles = require './CancelSubscriptionModal.stylus'

module.exports = CancelSubscriptionModal = (props) ->

  { isCanceling, isOpen, onConfirm, onCancel } = props

  modalProps =
    showAlien: no
    isOpen: isOpen
    onRequstClose: onCancel
    width: 'xlarge'
    height: 'tall'

  primaryTitle = if isCanceling
  then 'Canceling...'
  else 'Yes, Cancel Subscription'

  <Modal {...modalProps}>
    <Header title='Cancel Subscription' />
    <Content>
      <div className={styles.imageContainer}>
        <Image />
      </div>
      <div>
        <Label size="large" type="danger">
          <strong style={fontWeight: 'bold'}>
            You are about to cancel your team’s subscription
          </strong>
        </Label>
      </div>
      <div style={lineHeight: '20px'}>
        <Label size="medium">
          If you proceed, <strong>your subscription will be suspended
          immediately</strong>; you and your team will <strong>NOT</strong> be able to use Koding until
          you renew your subscription. Are you sure to cancel your subscription?
        </Label>
      </div>
    </Content>
    <Footer
      disabled={isCanceling}
      primaryButtonTitle={primaryTitle}
      primaryButtonSize='medium'
      onPrimaryButtonClick={onConfirm}
      secondaryButtonTitle='Close'
      secondaryButtonSize='medium'
      onSecondaryButtonClick={onCancel} />

  </Modal>


cancelSubImgSrc = require './cancel-sub.svg'
Image = ->

  <img src={cancelSubImgSrc} />
