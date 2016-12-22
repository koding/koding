React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

SupportPlanActivationModal = require 'lab/SupportPlanActivationModal'

storiesOf 'SupportPlanActivationModal', module
  .add 'default', ->

    <SupportPlanActivationModal
      isOpen={yes}
      title='Support Plan'
      label='Basic Support Plan'
      price='1,000'
      shouldCloseOnOverlayClick={yes}
      onCancel={action 'cancel clicked'}
      onActivateSupportPlanClick={action 'activate support plan clicked'} />
