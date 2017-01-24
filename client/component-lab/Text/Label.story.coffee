React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

Label = require './Label'

storiesOf 'Label', module
  .add 'small', -> <Label size="small">Hello World!</Label>
  .add 'medium', -> <Label size="medium">Hello World!</Label>
  .add 'large', -> <Label size="large">Hello World!</Label>
  .add 'xlarge', -> <Label size="xlarge">Hello World!</Label>

  .add 'small danger', -> <Label size="small" type="danger">Hello World!</Label>
  .add 'small success', -> <Label size="small" type="success">Hello World!</Label>
  .add 'small info', -> <Label size="small" type="info">Hello World!</Label>
