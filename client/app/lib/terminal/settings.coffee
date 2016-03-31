module.exports =
  fonts      : [
    { title  : 'Source Code Pro' , value: 'source-code-pro' }
    { title  : 'Ubuntu Mono'     , value: 'ubuntu-mono' }
  ]

  fontSizes  : (
    for i in [10, 11, 12, 13, 14, 16, 20, 24]
      { title: "#{i}px", value: i }
  )

  themes     : [
    { title  : 'Black on White'  , value: 'black-on-white' }
    { title  : 'Gray on Black'   , value: 'gray-on-black' }
    { title  : 'Green on Black'  , value: 'green-on-black' }
    { title  : 'Solarized Dark'  , value: 'solarized-dark' }
    { title  : 'Solarized Light' , value: 'solarized-light' }
  ]

  scrollback : [
    { title  : 'Unlimited'       , value: Number.MAX_VALUE }
    { title  : '50'              , value: 50 }
    { title  : '100'             , value: 100 }
    { title  : '1000'            , value: 1000 }
    { title  : '10000'           , value: 10000 }
  ]
