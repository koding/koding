React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

Box = require './Box'

storiesOf 'Box', module
  .add 'default', -> <Box />
  .add 'danger', -> <Box type="danger" />
  .add 'success', -> <Box type="success" />
  .add 'info', -> <Box type="info" />
  .add 'secondary', -> <Box type="secondary" />
  .add 'danger with border', -> <Box type="danger" border={1} />
  .add 'success with border', -> <Box type="success" border={1} />
  .add 'info with border', -> <Box type="info" border={1} />
  .add 'secondary with border', -> <Box type="secondary" border={1} />
