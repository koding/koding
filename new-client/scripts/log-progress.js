var Spinner = require('cli-spinner').Spinner

function logProgress(label) {
  var spinner = new Spinner(label)
  spinner.setSpinnerString(18)
  spinner.start()
  console.time(label)

  return function end() {
    spinner.stop(true)
    console.timeEnd(label)
  }
}

module.exports = logProgress

