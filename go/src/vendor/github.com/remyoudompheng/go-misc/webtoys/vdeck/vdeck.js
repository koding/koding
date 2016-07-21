// sortBy sorts an array according to some criterion.
function sortBy(data, criterion) {
    var keys = [];
    var newdata = [];
    for(var i in data) {
        var key = [criterion(data[i]), data[i]];
        keys.push(key);
    }
    keys.sort();
    for(var i in keys) {
        newdata.push(keys[i][1]);
    }
    return newdata;
};

function byField(name) {
    return function(x) { return x[name]; }
}

(function($) {

// The vdeck module.
$.vdeck = function() {};

// get_vcards updates the vCard data set.
$.vdeck.get_vcards = function() {
    $.getJSON("/vdeck/all", function(data) {
        $.vdeck.cards = data;
        $.vdeck.cards_by_name = {}
        for(var i in data) {
            $.vdeck.cards_by_name[data[i].filename] = data[i];
        }
        $.vdeck.fill_table();
    });
};

$.vdeck.setup_table = function() {
    var fields = ["fullname", "family_name", "first_name",
      "phone", "email", "filename"];
    var headers = $("table#contacts thead tr th");
    headers.each(function(i) {
        $(this).click(function() {
            if ($.vdeck.sort_table_field == fields[i]) {
                $.vdeck.sort_table_reverse ^= true;
            } else {
                $.vdeck.sort_table_reverse = false;
                $.vdeck.sort_table_field = fields[i];
            }
            $.vdeck.fill_table();
        });
    });
};

$.vdeck.cards = [];
$.vdeck.cards_by_name = {};
$.vdeck.sort_table_field = "filename";
$.vdeck.sort_table_reverse = false;

$.vdeck.fill_table = function(field) {
    $("table#contacts tbody").empty();
    var items = sortBy($.vdeck.cards, byField($.vdeck.sort_table_field));
    if ($.vdeck.sort_table_reverse)
        items.reverse();
    for(var i in items) {
        var item = items[i];
        var row = $("<tr/>")
            .append($("<td/>").text(item.fullname))
            .append($("<td/>").text(item.family_name))
            .append($("<td/>").text(item.first_name))
            .append($("<td/>").text(item.phone).addClass("phone"))
            .append($("<td/>").text(item.email))
            .append($("<td/>").text(item.filename));

        // vCard raw display handler.
        row.children(":nth-child(6)").dblclick(function() {
            var fname = $(this).text();
            $.get("/vdeck/vcf/" + fname, function(data) {
                $("#vcf-dialog .raw-vcard").text(data);
                $("#vcf-dialog").dialog("open");
            });
        });

        // vCard rich display handler.
        row.children().not(":nth-child(6)").dblclick(function() {
            var fname = $(this).parent().children(":nth-child(6)").text();
            var data = $.vdeck.cards_by_name[fname];
            $.getJSON("/vdeck/json/" + data.filename, $.vdeck.fill_vcard);
        });

        $("table#contacts tbody").append(row);
    }
};

// fill_vcard fills the editor with a given vCard.
$.vdeck.fill_vcard = function(data) {
    // Identification
    $("#input-fullname").val(data.FullName);
    $("#input-firstname").val(data.Name.GivenName);
    $("#input-familyname").val(data.Name.FamilyName);
    $("#input-nickname").val(data.NickName);
    $("#input-birthday").val(data.Birthday);

    // Contact
    $("#vcf-address tbody").empty();
    if (data.Address) {
        for(var i = 0; i < data.Address.length; i++) {
            var addr = data.Address[i];
            var row = $("<tr/>")
                .append($("<td/>").text(addr.POBox))
                .append($("<td/>").text(addr.ExtendedAddr))
                .append($("<td/>").text(addr.Street))
                .append($("<td/>").text(addr.Locality))
                .append($("<td/>").text(addr.Region))
                .append($("<td/>").text(addr.PostalCode))
                .append($("<td/>").text(addr.Country));
            $("#vcf-address tbody").append(row);
        }
    }

    $("#vcf-phone tbody").empty();
    if (data.Tel) {
        for(var i = 0; i < data.Tel.length; i++) {
            var row = $("<td/>").text(data.Tel[i].Value).wrap("<tr/>").parent();
            $("#vcf-phone tbody").append(row);
        }
    }

    $("#vcf-email tbody").empty();
    if (data.Email) {
        for(var i = 0; i < data.Email.length; i++) {
            var row = $("<td/>").text(data.Email[i].Value).wrap("<tr/>").parent();
            $("#vcf-email tbody").append(row);
        }
    }

    // Misc
    $("#input-categories").val(data.Categories);
    $("#input-uid").val(data.Uid);
    $("#input-url").val(data.Url);

    $("#vcf-editor").dialog("open");
};

$.vdeck.save_vcard = function() {
};

})(jQuery);

$(document).ready(function() {
    $.vdeck.setup_table();
    $.vdeck.get_vcards();

    $("#vcf-dialog").dialog({
        autoOpen: false,
        height:   400,
        width:    400,
        modal:    true,
        buttons: {
            "Close": function() { $(this).dialog("close"); },
        },
    });

    $("#vcf-editor").tabs().dialog({
        autoOpen: false,
        height:   650,
        width:    650,
        modal:    true,
        buttons: {
			"Save": $.vdeck.save_vcard,
            "Close": function() { $(this).dialog("close"); },
        },
    });

    $("fieldset input").addClass("ui-widget-content ui-corner-all");
});
