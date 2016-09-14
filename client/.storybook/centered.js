import React from 'react'

const style = {
  height: '100vh',
  width: '100vw',
  position: 'absolute',
  top: 0,
  left: 0,
  bottom: 0,
  right: 0,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center'
}

export default (story) => (
  <div style={style}>{story()}</div>
)

