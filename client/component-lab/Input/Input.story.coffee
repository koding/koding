React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

Input = require './Input'

storiesOf 'Input', module
  .add 'small input', ->
    <Input size='small' placeholder='Placeholder...' />

  .add 'medium input', ->
    <Input size='medium' placeholder='Placeholder...' />

  .add 'auto medium input', ->
    <div style={{display: 'flex', width: '100%'}}>
      <Input size='medium' auto placeholder='Placeholder...' />
    </div>

  .add 'auto medium input/redux field', ->
    <div style={{display: 'flex', width: '100%'}}>
      <Input.Field name='foo' size='medium' auto placeholder='Placeholder...' />
    </div>

  .add 'medium input with field title', ->
    <div>
      <div style={{display: 'flex', width: '100%'}}>
        <Input title='Your email' size='medium' auto placeholder='Placeholder...' />
      </div>
      <div style={{display: 'flex', width: '100%'}}>
        <Input title='Your email' size='medium' auto placeholder='Placeholder...' />
      </div>
    </div>
