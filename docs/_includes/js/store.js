document.querySelector('.dropdown').onclick = function() {

  if (this.classList.contains('is-shown')) {
    this.classList.remove('is-shown');
  } else {
    this.classList.add('is-shown');
  }
};

[].forEach.call( document.querySelectorAll('.dropdown .dropdown-options a'), function(el) {
  el.addEventListener('click', function() {
    document.querySelector('.dropdown-selection label').innerHTML = this.innerHTML;
    document.querySelector('.search-bar input').focus();
  }, false)
});

document.querySelector('.search-bar input').onkeyup = function(e) {
  submitInput(this);
}

document.querySelector('.search-icon').onclick = function(e) {
  var el = document.querySelector('.search-bar input');
  submitInput(el);
}

document.querySelector('.remove-icon').onclick = function(e) {
  document.querySelector('.search-bar input').value = "";
  document.querySelector('.search-bar input').focus();
  document.querySelector('.search-bar').classList.remove('is-shown');
  document.querySelector('.search-results-rows').innerHTML = "";
}

var searchResultTemplate = function(obj) {
  return '<a class="search-result-row">' +
          '<p class="title">' + obj.formattedTitle + (obj.verified ? '<span class="icon verified"></span>' : '') + '</p>' +
          '<p class="description">by '+ obj.author +'</p>' +
        '</a>';
}

var submitInput = function(e) {
  if (e.value != "") {
    var filteredStacks = stacks.filter(function(obj) {
      return obj.title.toLowerCase().indexOf(e.value) != -1;
    }).slice(0, 5);
    
    var html = filteredStacks.map(function(obj) {
      var indexOf = obj.title.toLowerCase().indexOf(e.value);
      var len = e.value.length;

      var start = obj.title.substr(0, indexOf);
      var middle = '<span class="matched-phrase">' + obj.title.substr(indexOf, len) + '</span>';
      var end = obj.title.substr(indexOf + len);
      obj.formattedTitle = start + middle + end;

      return searchResultTemplate(obj);
    }).join('');

    document.querySelector('.search-bar').classList.add('is-shown');
    document.querySelector('.search-results-rows').innerHTML = html;
  } else {
    document.querySelector('.search-bar').classList.remove('is-shown');
    document.querySelector('.search-results-rows').innerHTML = "";
  }
}

var stacks = {{site.data.store-stacks | jsonify }}