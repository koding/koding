(function() {

  var searchBar      = document.querySelector('.SearchBar'),
      searchBarInput = document.querySelector('.SearchBar input'),
      searchResults  = document.querySelector('.SearchBar-resultsData'),

      dropdown        = document.querySelector('.Dropdown'),
      dropdownLabel   = document.querySelector('.Dropdown-selection')
      dropdownOptions = document.querySelectorAll('.Dropdown .Dropdown-options a'),

      removeIcon = document.querySelector('.remove-icon'),

      modalContent = document.querySelector('.modal-content');

      itemDetailsTabs = document.querySelectorAll('.ItemDetails ul li');

  var initialize = function() {

    if (dropdown) {
      [].forEach.call( dropdownOptions, function(el) {
        el.addEventListener('click', function() {

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
    }

    if (searchBar) {
      searchBarInput.addEventListener('keyup', submitInput.bind(searchBarInput));

      removeIcon.addEventListener('click', function(e) {
        searchBarInput.value = "";
        searchBarInput.focus();
        searchBar.classList.remove('isShown');
        searchResults.innerHTML = "";

        return false;
      });
    }

    if (itemDetailsTabs) {
      [].forEach.call(itemDetailsTabs, function(el) {
        el.addEventListener('click', selectTab);
      });
    }

    if (modalContent && LANDING_UTILS.modal) {
      var modalOptions = {};
      modalOptions.content = modalContent.innerHTML;

      LANDING_UTILS.modal(modalOptions);
    }
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

  var submitInput = function() {

    var items, 
        filteredItems = [],
        html = "",
        value = this.value.trim();

    if (value != "") {

      // Dropdown does not appear on Stacks-only page
      if (dropdown) {
        items = dropdownLabel.classList.contains('stacks') ? stacks : stencils;
      } else {
        items = stacks;
      }

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

  var selectTab = function() {
    document.querySelector('.ItemDetails ul li.isSelected').classList.remove('isSelected');
    document.querySelector('.ItemBody-content .isShown').classList.remove('isShown');

    var self = this;
    setTimeout(function() {
      self.classList.add('isSelected');
      document.querySelector('.ItemBody-content .ItemBody-content-'+self.id).classList.add('isShown');
    }, 0)
  }

  var stacks = {{site.data.store-stacks | jsonify }},
      stencils = {{site.data.store-stencils | jsonify }};

  initialize();
})();