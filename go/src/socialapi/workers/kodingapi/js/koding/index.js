module.exports = (function(o) {
  o.baseUrl || (o.baseUrl = '');
  return {
    Machine: require('./machine')(o),
  };
})(o);