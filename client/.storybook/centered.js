import React from 'react'

const style = {
  height: '100vh',
  position: 'absolute',
  top: 0,
  left: 30,
  bottom: 0,
  right: 30,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center'
}

export default (story) => (
  <div style={style}>
    <div style={{width: '100%'}}>
      {story()}
    </div>
  </div>
)

