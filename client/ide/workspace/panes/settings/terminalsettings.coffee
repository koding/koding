module.exports =
  fonts     : [
    { value : 'source-code-pro', title : 'Source Code Pro' }
    { value : 'ubuntu-mono'    , title : 'Ubuntu Mono'     }
  ]

  fontSizes: [
    { value: 10, title: '10px' }
    { value: 11, title: '11px' }
    { value: 12, title: '12px' }
    { value: 13, title: '13px' }
    { value: 14, title: '14px' }
    { value: 16, title: '16px' }
    { value: 20, title: '20px' }
    { value: 24, title: '24px' }
  ]

  themes:
    [
      { title: 'Black on White' , value: 'black-on-white'  }
      { title: 'Gray on Black'  , value: 'gray-on-black'   }
      { title: 'Green on Black' , value: 'green-on-black'  }
      { title: 'Solarized Dark' , value: 'solarized-dark'  }
      { title: 'Solarized Light', value: 'solarized-light' }
    ]

  scrollback:
    [
      { title: 'Unlimited', value: Number.MAX_VALUE }
      { title: '50'       , value: 50               }
      { title: '100'      , value: 100              }
      { title: '1000'     , value: 1000             }
      { title: '10000'    , value: 10000            }
    ]
