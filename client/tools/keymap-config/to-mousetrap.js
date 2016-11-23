
module.exports = function (af) {
  if (!af || af == 'null')
    return null;
  return af.toLowerCase().replace(/-/g, '+');
};