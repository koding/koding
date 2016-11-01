React = require 'react'

{ Header, Content, Footer } = Modal = require 'lab/Modal'
Label = require 'lab/Text/Label'

styles = require './SubscriptionSuccessModal.stylus'

module.exports = SubscriptionSuccessModal = (props) ->

  { isOpen, onInviteMembersClick, onCancel } = props

  modalProps =
    showAlien: no
    isOpen: isOpen
    onRequstClose: onCancel

  <Modal {...modalProps}>
    <Header title='Congratulations!' />
    <Content>
      <div className={styles.imageContainer}>
        <figure className={styles.image} />
      </div>
      <div>
        <Label size="small" type="info">
          Welcome to the Koding family. If there is anything we can ever do for
          you, don’t hesitate to reach out to us. You will be billed monthly
          based upon the number of members in your team.
        </Label>
      </div>
    </Content>
    <Footer
      primaryButtonTitle='INVITE TEAM MEMBERS'
      onPrimaryButtonClick={onInviteMembersClick}
      secondaryButtonTitle='CLOSE'
      onSecondaryButtonClick={onCancel} />

  </Modal>
