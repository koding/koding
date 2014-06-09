processes = new(require 'processes')

{argv} = require 'optimist'

processes.run
  name    : argv.n ? 'kite'
  cmd     : "coffee #{argv._} -c #{argv.c}"
  restart : yes
  restartInterval : 1000
  stdout  : process.stdout
  stderr  : process.stderr
  verbose : yes