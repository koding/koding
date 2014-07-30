do ->
    unless 'first' of Array.prototype
      Object.defineProperty Array.prototype, 'first',
        get : -> this[0]
    unless 'last' of Array.prototype
      Object.defineProperty Array.prototype, 'last',
        get : -> this[this.length-1]
