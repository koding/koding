React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

Button = require './Button'

storiesOf 'Button', module
  .add 'xlarge button', ->
    <div>
      <Button type="primary-1" size="xlarge">primary-1</Button>
      <Button type="primary-2" size="xlarge">primary-2</Button>
      <Button type="primary-3" size="xlarge">primary-3</Button>
      <Button type="primary-4" size="xlarge">primary-4</Button>
      <Button type="primary-5" size="xlarge">primary-5</Button>
      <Button type="primary-6" size="xlarge">primary-6</Button>
      <Button type="link-primary-1" size="xlarge">link-primary-1</Button>
      <Button type="link-primary-2" size="xlarge">link-primary-2</Button>
      <Button type="link-primary-3" size="xlarge">link-primary-3</Button>
      <Button type="link-primary-4" size="xlarge">link-primary-4</Button>
      <Button type="link-primary-5" size="xlarge">link-primary-5</Button>
      <Button type="link-primary-6" size="xlarge">link-primary-6</Button>
    </div>

  .add 'large button', ->
    <div>
      <Button type="primary-1" size="large">primary-1</Button>
      <Button type="primary-2" size="large">primary-2</Button>
      <Button type="primary-3" size="large">primary-3</Button>
      <Button type="primary-4" size="large">primary-4</Button>
      <Button type="primary-5" size="large">primary-5</Button>
      <Button type="primary-6" size="large">primary-6</Button>
      <Button type="link-primary-1" size="large">link-primary-1</Button>
      <Button type="link-primary-2" size="large">link-primary-2</Button>
      <Button type="link-primary-3" size="large">link-primary-3</Button>
      <Button type="link-primary-4" size="large">link-primary-4</Button>
      <Button type="link-primary-5" size="large">link-primary-5</Button>
      <Button type="link-primary-6" size="large">link-primary-6</Button>
    </div>

  .add 'medium button', ->
    <div>
      <Button type="primary-1" size="medium">primary-1</Button>
      <Button type="primary-2" size="medium">primary-2</Button>
      <Button type="primary-3" size="medium">primary-3</Button>
      <Button type="primary-4" size="medium">primary-4</Button>
      <Button type="primary-5" size="medium">primary-5</Button>
      <Button type="primary-6" size="medium">primary-6</Button>
      <Button type="link-primary-1" size="medium">link-primary-1</Button>
      <Button type="link-primary-2" size="medium">link-primary-2</Button>
      <Button type="link-primary-3" size="medium">link-primary-3</Button>
      <Button type="link-primary-4" size="medium">link-primary-4</Button>
      <Button type="link-primary-5" size="medium">link-primary-5</Button>
      <Button type="link-primary-6" size="medium">link-primary-6</Button>
    </div>

  .add 'small button', ->
    <div>
      <Button type="primary-1" size="small">primary-1</Button>
      <Button type="primary-2" size="small">primary-2</Button>
      <Button type="primary-3" size="small">primary-3</Button>
      <Button type="primary-4" size="small">primary-4</Button>
      <Button type="primary-5" size="small">primary-5</Button>
      <Button type="primary-6" size="small">primary-6</Button>
      <Button type="link-primary-1" size="small">link-primary-1</Button>
      <Button type="link-primary-2" size="small">link-primary-2</Button>
      <Button type="link-primary-3" size="small">link-primary-3</Button>
      <Button type="link-primary-4" size="small">link-primary-4</Button>
      <Button type="link-primary-5" size="small">link-primary-5</Button>
      <Button type="link-primary-6" size="small">link-primary-6</Button>
    </div>

  .add 'full width button', ->
    <div style={{width: '100%'}}>
      <div style={{marginBottom: '5px'}}><Button type="primary-1" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="primary-2" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="primary-3" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="primary-4" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="primary-5" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="primary-6" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="secondary" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="primary" auto disabled>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="secondary" auto disabled>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="link-primary-1" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="link-primary-2" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="link-primary-3" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="link-primary-4" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="link-primary-5" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="link-primary-6" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="link-secondary" auto>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="link-primary" auto disabled>Next</Button></div>
      <div style={{marginBottom: '5px'}}><Button type="link-secondary" auto disabled>Next</Button></div>
    </div>
