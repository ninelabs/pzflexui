$(document).ready(function() {
  $("figure").each(function() {
    $("#local-nav").append('<li><a href="#' + $( this ).data("label") + '">' + $( this ).text() + '</a></li>');
  });
});
