document.write = document.writeln = function () {
  throw new Error('document.[write|writeln] is nisht-nisht');
};