(function () {

    var FORM_SELECTOR     = "#SignupForm";
    var INPUT_SELECTOR    = "#SignupForm input";
    var TEXTAREA_SELECTOR = "#SignupForm textarea";
    var PASSWORD_SELECTOR = "#SignupForm .password input";
    var TEAMNAME_SELECTOR = "input[name=team_url]";
    var USERNAME_SELECTOR = "input[name=username]"
    var SUBMIT_SELECTOR   = "#SignupForm button"
    var STRENGTH_MAP      = [ "weak", "mediocre", "good", "strong", "very-strong"];


    // var KODING_URL = "http://dev.koding.com:8090"
    // var KODING_URL_PREFIX = "http://"
    // var KODING_URL_SUFFIX = ".dev.koding.com:8090"

    var KODING_URL = "https://koding.com"
    var KODING_URL_PREFIX = "https://"
    var KODING_URL_SUFFIX = ".koding.com"

    // make sure form is on the page
    var timer = setInterval(function (){
        // wait until form fields are put, hubspot puts them in lazily
        if (document.querySelectorAll(INPUT_SELECTOR).length > 3) {
            formReady();
            clearInterval(timer);
        }
    }, 200);

    // set autosize for textareas in the form
    var setAutosize = function (textareas) {
        if (!autosize) return;
        Array.prototype.forEach.call(textareas, function(textarea) {
            textarea.setAttribute("rows", 1)
        })
        autosize(textareas);
    }

    // execute things once form is on the page
    var formReady = function () {
        var textareas = document.querySelectorAll(TEXTAREA_SELECTOR);
        if (textareas.length) setAutosize(textareas);

        $(INPUT_SELECTOR).on("focus", function (event) {
            var $input  = $(event.target);
            var $legend = $input.prev();
            if (!$legend.html()) return;
            $legend.css("opacity", 1);
        });

        $(INPUT_SELECTOR).on("blur", function (event) {
            var $input  = $(event.target);
            var $legend = $input.prev();
            if (!$legend.html()) return;
            $legend.css("opacity", 0);
        });

        $(PASSWORD_SELECTOR).on("keyup", function (event) {
            var $legend = $(this).prev();
            var strength = $.pwstrength($(PASSWORD_SELECTOR).val());
            STRENGTH_MAP.forEach(function (cls) { $legend.removeClass(cls); });
            $legend.attr("data-strength", "Strength: " + STRENGTH_MAP[strength]);
        });

        window.formSubmitted = false;
        window._respToken = null

        document.addEventListener('submit',function (event) {

            formContainer = document.getElementById('SignupForm');
            if (!formContainer || !formContainer.contains(event.target)) return;

            event.stopPropagation();
            event.preventDefault();

            var $form = $(FORM_SELECTOR);
            var $password = $form.find(PASSWORD_SELECTOR)
            var $teamName = $form.find(TEAMNAME_SELECTOR)
            var $username = $form.find(USERNAME_SELECTOR)
            var $submitButton = $form.find(SUBMIT_SELECTOR)

            // cleanup custom errors.
            cleanupErrors([$teamName, $password, $username])

            var formData = $form.serializeArray().reduce(function(acc, input) {
                var name = input.name

                if (name === 'firstname', name === 'lastname') {
                    name = name.replace('name', 'Name')
                }
                acc[name] = input.value;
                return acc;
            }, {})

            formData.companyName = formData.team_url || ''
            formData.slug = slugify(formData.companyName)

            formData.agree = 'on'
            formData.passwordConfirm = formData.password
            formData.alreadyMember = 'true'

            if (window.formSubmitted && $password.val() === 'censored') {
                var nextUrl;

                // There are some times where create team response doesn't return a JWT token,
                // redirect user to the teamname.koding.com/Login as fallback.
                if (window._respToken) {
                    nextUrl = KODING_URL_PREFIX + formData.slug + KODING_URL_SUFFIX + "/-/loginwithtoken?token=" + window._respToken
                } else {
                    nextUrl = KODING_URL_PREFIX + formData.slug + KODING_URL_SUFFIX + "/Login"
                }
                location.replace(nextUrl)
                return false
            }

            setButtonLoading($submitButton, true)

            function toLowerCase(word) {
                return word.split(' ').map(function(word) { return word.trim().toLowerCase() }).join('')
            }

            function getPermission(callback) {
                $.ajax({
                    url: KODING_URL + '/-/teams/allow',
                    type: 'POST',
                    success: function(res) {
                        callback(null, res)
                    },
                    error: function(err) {
                        callback(err)
                    }
                });
            }

            function validateEmail(email, callback) {
                email = email || ''

                if (!isValidEmail(email)) {
                    return callback({ message: 'Email must be formatted correctly.', decoratedMessage: true })
                }

                return callback(null)
            }

            function validateUsername(username, callback) {

                if (username.indexOf('@') > -1) {
                    return validateEmail(username, callback)
                }

                if (username.length < 4 || username.length > 25) {
                    return callback({ message: 'Username should be between 4 and 25 characters!', decoratedMessage: true })
                }

                if (!(/^[a-z0-9][a-z0-9-]+$/.test(username))) {
                    return callback({ message: 'For username only lowercase letters and numbers are allowed!', decoratedMessage: true })
                }

                return callback(null)
            }

            function validateTeamName(name, callback) {

                if (name.length < 3) {
                    return callback({ message: 'Username should be longer than 2 characters.', decoratedMessage: true })
                }

                if (!(/^[a-z0-9][a-z0-9-]+$/.test(name))) {
                    return callback({ message: 'For usernames only letters and numbers are allowed!', decoratedMessage: true })
                }

                return $.ajax({
                    url: KODING_URL + '/-/teams/verify-domain',
                    type: 'POST',
                    data: { name: name },
                    success: function(res) { callback(null, res) },
                    error: function(err) { callback(err) }
                })
            }

            function createTeam(data, callback) {
                $.ajax({
                    url: KODING_URL + '/-/teams/create',
                    data: data,
                    type: 'POST',
                    success: function(res) {
                        callback(null, res)
                    },
                    error: function(err) {
                        callback(err)
                    }
                });
            }

            if ((formData.username || formData.koding_username) === formData.slug) {
                showError($teamName, getTeamNameUserNameError())
                setButtonLoading($submitButton, false)
                window.formSubmitted = false
                return;
            }

            getPermission(function(err, res) {

                var username = (formData.username || formData.koding_username || '').toLowerCase()

                validateUsername(username, function(err) {
                    if (err) {
                        if (err.decoratedMessage) {
                            showError($username, err.message)
                        }

                        setTimeout(setButtonLoading.bind(null, $submitButton, false), 10)
                        window.formSubmitted = false
                        return;
                    }

                    validateTeamName(formData.slug, function(err) {
                        if (err) {
                            if (err.decoratedMessage) {
                                showError($teamName, err.message)
                            } else {
                                showError($teamName, getTeamNameNotAvailableError())
                            }
                            setButtonLoading($submitButton, false)
                            window.formSubmitted = false
                            return;
                        }

                        createTeam(formData, function(err, resp) {
                            if (err) {
                                if (err.status === 403) {
                                    var errorResponse = JSON.parse(err.responseText)
                                    $teamName.val(errorResponse.suggested).change();
                                    showError($teamName, getSuggestedTeamNameError(errorResponse.suggested, formData.slug))
                                    formData.slug = errorResponse.suggested
                                }
                                else if (err.status === 400 && err.responseText === 'Access denied!') {
                                    showError($password, getPasswordError())
                                }
                                else if (err.status === 400 && /access is blocked/.test(err.responseText)) {
                                    showError($password, makeError(err.responseText))
                                }
                                else if (err.status === 400 && /Unknown user/.test(err.responseText)) {
                                    showError($username, makeError("Unknown username"))
                                } else {
                                    showError($teamName, 'There is a problem with the information you entered, please update and resend the form.')
                                }

                                setButtonLoading($submitButton, false)
                                window.formSubmitted = false;
                                return;
                            }
                            $password.val('censored').change()
                            window.formSubmitted = true;
                            window._respToken = resp.token
                            $submitButton.click()
                        })
                    })
                })
            })

            return false;

        }, true);

        function setButtonLoading($button, isLoading) {
            if (isLoading) {
                $button.val('CREATING YOUR TEAM...').css('opacity', '0.5')
            } else {
                $button.val('GET STARTED').css('opacity', '1')
            }
        }

        function getSuggestedTeamNameError(suggested, original) {
            return $(
                '<ul class="errors" style="display:block;"><li><label><strong>'+ original +'</strong> is not available. We replaced it with <strong>'+ suggested +'</strong> for you.</label></li></ul>'
            )
        }

        function getTeamNameNotAvailableError() {
            return $(
                '<ul class="errors" style="display:block;"><li><label>Team name is unavailable. Please try with another one.</label></li></ul>'
            )
        }

        function getTeamNameUserNameError() {
            return $(
                '<ul class="errors" style="display:block;"><li><label>Your username and team name cannot be the same</label></li></ul>'
            )
        }

        function getPasswordError() {
            return $(
                '<ul id="password-error" class="hs-error-msgs inputs-list" style="display:block;"><li><label>Given credentials doesn\'t match!</label></li><li><label><a href="https://koding.com/Recover">Forgot Password?</a></label></li></ul>'
            )
        }

        function getEmailError() {
            return $(
                '<ul class="errors" style="display:block;"><li><label>Email is taken. Please try another one.</label></li></ul>'
            )
        }

        function makeError(content) {
            return $(
                '<ul class="errors" style="display:block;"><li><label>' + content + '</label></li></ul>'
            )
        }

        function cleanupErrors($errors) {
            $errors.forEach(function ($error) {
                $error.removeClass('invalid error')
                    .parent()
                    .parent()
                    .find('.errors')
                    .remove()
            })
        }

        function showError($el, errMsg) {
            if (typeof errMsg === 'string') {
                errMsg = makeError(errMsg)
            }

            $el.one('focus', function() {
                cleanupErrors([$el])
            })

            $el.parent().find('.errors').remove()
            $el
                .addClass('invalid error')
                .parent()
                .remove('.errors')
                .append(
                    errMsg
                )
        }

        function slugify(text) {
            if (!text) {
                return ''
            }

            return text.split(' ').map(function(word) {
                return word.trim()
            }).filter(Boolean).join('-')
        }

        function isValidEmail(email) {
          var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
          return re.test(email);
        }
    }

})();
