$(document).ready(function(){
  var p = $("#canvas");
  var position = p.position();

  $('#signon').click(function(e){
    $('#session_height').val($(window).height());
    $('#session_width').val($(window).width());
  });

  $('#canvas').mousedown(function(e){
    $('#context_action').val("CLICK " + e.which + " " +
      (e.pageX - position.left) + " " +
      (e.pageY - position.top)
    );
  
    $("#update_button").click();
  });

  $(document).keypress(function(e) {
    var shift = "FALSE";
    if ( e.shiftKey ) {
      shift = "TRUE";
    }

    $('#context_action').val("KEY " + 
      shift + " " +
      (e.which)
    );
  
    $("#update_button").click();
  });

  $('#player_options').click(function(e){
    var options = "";
    $("input[type=checkbox]:checked").each( 
      function() {
        options = options + $(this).attr("id") + " "; 
      } 
    );
    $('#context_action').val("ENABLE " + options);
      
    $("#update_button").click();

  });    

})
