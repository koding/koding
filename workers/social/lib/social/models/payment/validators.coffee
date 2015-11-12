module.exports =

  fee: [
    'invalid fee amount'
    (value) -> not value? or value >= 0
  ]


