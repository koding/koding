React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

TrialExpireWarning = require './TrialExpireWarning'

storiesOf 'TrialExpireWarning', module
  .add 'default', -> <TrialExpireWarning />


