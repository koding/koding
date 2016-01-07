kd = require 'kd'
React = require 'kd-react'
Modal = require 'app/components/modal'

module.exports = class CollaborationComingSoonModal extends React.Component

  @defaultProps =
    isOpen         : no
    onClose        : kd.noop


  render: ->
    <Modal className='CollaborationComingSoonModal' isOpen={@props.isOpen} onClose={@props.onClose}>
      <div className='CollaborationComingSoonModal-header'>
        <h3>Start a video chat in any channel</h3>
        <span>Coming really soon...</span>
      </div>
      <div className='CollaborationComingSoonModal-content'>
        <img src='/a/images/activity/coming-soon-modal-content.png'/>
      </div>
    </Modal>
