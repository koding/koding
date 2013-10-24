$('.dropdown-toggle').dropdown();
$(
	function(){
		var form = $('#switchVersionForm')
		var switchButton = $('#switchButton')
		$(switchButton).click(
			function(){ //listen for click event
			    showPasswordModal(function(){$(form).submit();});
			})
	}
)
// modal for user s password
var showPasswordModal = function(callback) {
	callback: callback;
    enterPass = function(e) {
        var modalSwitcherPass = $("#modalSwitcherPass")[0]
        if (modalSwitcherPass.value !== "") {
            var switcherPass = $("#switcherPass")[0]
            switcherPass.value = modalSwitcherPass.value
            $("#myModal").modal('hide');
            callback();
        }
    }
    $("#myModal").bind("submit", enterPass);
    $("#myModal").bind("show", function() {
        $("#myModal a.primary").click(function(e) {
            enterPass();
        });
        $("#myModal a.inverse").click(function(e) {
	        $("#myModal").modal('hide');
        });

    });
 
    // remove the event listeners when the dialog is hidden
    $("#myModal").bind("hide", function() {
        // remove event listeners on the buttons
        $("#myModal a.btn").unbind();
    });
 
    $("#myModal").modal({
      "backdrop"  : "static",
      "keyboard"  : true,
      "show"      : true    // this parameter ensures the modal is shown immediately
    });
};