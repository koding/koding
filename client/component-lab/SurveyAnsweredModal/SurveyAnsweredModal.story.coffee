React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

SurveyAnsweredModal = require './SurveyAnsweredModal'

storiesOf 'SurveyAnsweredModal', module
  .add 'default', ->
    <SurveyAnsweredModal
      isOpen={yes}
      onButtonClick={action 'button clicked'} />
