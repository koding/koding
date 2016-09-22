(function() {
  var searchBar      = document.querySelector('.search-bar'),
      searchBarInput = document.querySelector('.search-bar input'),
      searchResults  = document.querySelector('.search-results-rows'),

      dropdown        = document.querySelector('.dropdown'),
      dropdownLabel   = document.querySelector('.dropdown-selection label')
      dropdownOptions = document.querySelectorAll('.dropdown .dropdown-options a'),

      removeIcon = document.querySelector('.remove-icon');

  dropdown.addEventListener('click', function() {

    if (this.classList.contains('is-shown')) {
      this.classList.remove('is-shown');
    } else {
      this.classList.add('is-shown');
    }
  });

  [].forEach.call( dropdownOptions, function(el) {
    el.addEventListener('click', function() {
      dropdownLabel.innerHTML = this.innerHTML;
      searchBarInput.focus();
    }, false)
  });

  searchBarInput.addEventListener('keyup', function(e) {
    submitInput(this);
  });

  removeIcon.addEventListener('click', function(e) {
    searchBarInput.value = "";
    searchBarInput.focus();
    searchBar.classList.remove('is-shown');
    searchResults.innerHTML = "";

    return false;
  });

  var searchResultTemplate = function(obj) {
    return '<a class="search-result-row">' +
      '<p class="title">' + obj.formattedTitle + (obj.verified ? '<span class="icon verified"></span>' : '') + '</p>' +
      '<p class="description">by '+ obj.author +'</p>' +
      '</a>';
  }

  var wrapMatchedText = function(title, matchedText, openTag, closeTag) {
    var indexOf = title.toLowerCase().indexOf(matchedText),
        len     = matchedText.length;

    var start  = title.substr(0, indexOf),
        middle = openTag + title.substr(indexOf, len) + closeTag,
        end    = title.substr(indexOf + len);

    return start + middle + end;
  }

  var submitInput = function(e) {
    var html = "";

    if (e.value != "") {
      var filteredStacks = stacks.filter(function(obj) {
        return obj.title.toLowerCase().indexOf(e.value) != -1;
      }).slice(0, 5);
      
      html = filteredStacks.map(function(obj) {
        obj.formattedTitle = wrapMatchedText(obj.title, e.value, '<span class="matched-phrase">', '</span>');
        return searchResultTemplate(obj);
      }).join('');

      searchBar.classList.add('is-shown');
    } else {
      searchBar.classList.remove('is-shown');
    }

    searchResults.innerHTML = html;
  }

  var stacks = {{site.data.store-stacks | jsonify }}
})();