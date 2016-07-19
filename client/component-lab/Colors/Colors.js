import React from 'react'

import classes from './Colors.css'

console.log({classes})

const SingleColor = ({ color, title }) => {

  const bgClassName = classes[`bg-${color}`]
  const colorClassName = classes['color-additional-2']

  return (
    <div style={{flex: '1', padding: '1em 0 0 1em'}}>
      <div className={bgClassName} style={{height: '40px'}}> </div>
      <div className={colorClassName} style={{textAlign: 'center'}}>
        {title}
      </div>
    </div>
  )
}

const subTypes = [
  '',
  'light',
  'dark',
  'darker',
  'faded',
  'faded-light',
  'faded-lighter'
]

const Colors = ({ title, type }) => {

  const color = subtype => [type, subtype].filter(Boolean).join('-')
  const toSigleColor = (subtype, index) => (
    <SingleColor key={index} color={color(subtype)} title={subtype || type} />
  )

  return (
    <div className='Colors'>
      <h3>{title}</h3>
      <div style={{display: 'flex', margin: '-1em 0 1em -1em'}}>
        {subTypes.map(toSigleColor)}
      </div>
    </div>
  )
}

Colors.propTypes = {
  /**
   * Title of the color box.
   */
  title: React.PropTypes.string,

  /**
  * Color code of the color wants to be rendered.
  */
  type: React.PropTypes.string
}

Colors.defaultProps = {
  title: 'Primary 1',
  type: 'primary-1'
}

export default Colors
