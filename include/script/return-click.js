$(document).keyup(function(event) {
    if ($("#researcher_name").is(":focus") && (event.keyCode == 13)) {
        $("#search_researcher").click();
    }
});

$(document).keyup(function(event) {
    if ($("#user_mail").is(":focus") && (event.keyCode == 13)) {
        $("#request_report").click();
    }
});