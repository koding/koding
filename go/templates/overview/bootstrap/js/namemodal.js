$('.dropdown-toggle').dropdown();
$(
    function(){
        var form = $('#switchVersionForm')
        var switchButton = $('#switchButton')
        $(switchButton).click(
            function(){ //listen for click event
            showNameModal(function(){$(form).submit();});
            })
    }
)
// modal for user s name
var showNameModal = function(callback) {
    callback: callback;
    $("#myModal").bind("show", function() {
        debugger
        $("#myModal a.primary").click(function(e) {
            var modalSwitcherName = $("#modalSwitcherName")[0]
            if (modalSwitcherName.value !== "") {
                var switcherName = $("#switcherName")[0]
                switcherName.value = modalSwitcherName.value
                $("#myModal").modal('hide');
                callback();
            }
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