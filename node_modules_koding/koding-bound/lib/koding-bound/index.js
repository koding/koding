module.exports = function(method) {
  var boundMethod;
  if (this[method] == null) {
    throw new Error("@bound: unknown method! " + method);
  }
  boundMethod = "__bound__" + method;
  boundMethod in this || Object.defineProperty(this, boundMethod, {
    value: this[method].bind(this)
  });
  return this[boundMethod];
};
