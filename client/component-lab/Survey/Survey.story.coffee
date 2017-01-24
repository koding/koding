React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

Survey = require './Survey'

storiesOf 'Survey', module
  .add 'default', -> <Survey />
