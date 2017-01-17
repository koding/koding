React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

VerifyEmailWarning = require './VerifyEmailWarning'

storiesOf 'VerifyEmailWarning', module
  .add 'default', -> <VerifyEmailWarning />
