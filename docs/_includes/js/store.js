(function() {
  var searchBar      = document.querySelector('.SearchBar'),
      searchBarInput = document.querySelector('.SearchBar input'),
      searchResults  = document.querySelector('.SearchBar-resultsData'),

      dropdown        = document.querySelector('.Dropdown'),
      dropdownLabel   = document.querySelector('.Dropdown-selection')
      dropdownOptions = document.querySelectorAll('.Dropdown .Dropdown-options a'),

      removeIcon = document.querySelector('.remove-icon');

  var initialize = function() {

    document.addEventListener('click', function(e) {
      if (e.target.id != "dropdown-selection" && dropdown.classList.contains('is-shown')) {
        dropdown.classList.remove('is-shown');
      }
    }, true);

    dropdown.addEventListener('click', function() {

      if (this.classList.contains('is-shown')) {
        this.classList.remove('is-shown');
      } else {
        this.classList.add('is-shown');
      }

      return false;
    });

    [].forEach.call( dropdownOptions, function(el) {
      el.addEventListener('click', function() {
        dropdownLabel.innerHTML = this.innerHTML;

        if (this.classList.contains('stacks')) {
          dropdownLabel.classList.remove('stencils');
          dropdownLabel.classList.add('stacks');
        } else {
          dropdownLabel.classList.remove('stacks');
          dropdownLabel.classList.add('stencils');
        }

        searchBarInput.focus();
      }, false)
    });

    searchBarInput.addEventListener('keyup', submitInput.bind(searchBarInput));

    removeIcon.addEventListener('click', function(e) {
      searchBarInput.value = "";
      searchBarInput.focus();
      searchBar.classList.remove('is-shown');
      searchResults.innerHTML = "";

      return false;
    });
  }

  var searchResultTemplate = function(obj) {
    return '<a class="SearchBar-resultsData-row">' +
      '<p class="title">' + obj.formattedTitle + (obj.verified ? '<span class="u-icon u-verified"></span>' : '') + '</p>' +
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
    var items, 
        filteredItems = [],
        e = e.target,
        html = "",
        value = e.value.trim();

    if (value != "") {

      items = dropdownLabel.classList.contains('stacks') ? stacks : stencils;

      filteredItems = items.filter(function(obj) {
        return obj.title.toLowerCase().indexOf(value) != -1;
      }).slice(0, 5);
      
      html = filteredItems.map(function(obj) {
        obj.formattedTitle = wrapMatchedText(obj.title, value, '<span class="matched-phrase">', '</span>');
        return searchResultTemplate(obj);
      }).join('');

      searchBar.classList.add('is-shown');
    } else {
      searchBar.classList.remove('is-shown');
    }

    searchResults.innerHTML = html;
  }

  var stacks = {{site.data.store-stacks | jsonify }},
      stencils = {{site.data.store-stencils | jsonify }};

  initialize();
})();