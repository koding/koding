module.exports = {
  reporter: function(results) {
    var failed = results.failed,
        errors = results.errors;

    if (failed === 0 && errors === 0) {
      process.exit(0);
    } else {
      process.exit(1);
    }
  }
};
