/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
//Terminal=require("./terminal").Terminal;
TerminalController=require("./terminal_controller").TerminalController;

function displayScreen(screen){
    console.log("Screen:##################################");
    for(i=0;i<screen.rows;i++){
        console.log(screen.row(i));
    }
    console.log("###########################################");
}


console.log("starting the test");
var controller=new TerminalController(200); //session timeout
        
try
{
        
    

    var id=controller.create("/bin/bash",50,50);
    console.log("id="+id);
    controller.bind(id,"screenDidChange",function(screen,data){
        console.log("screen just changed [custom_data="+data+"]"); 
        displayScreen(screen);
    });
    controller.emit(id,"screenDidChange","screen id="+id);
    controller.emit(id,"error","screen id="+id);
    controller.bind(id,"error",function(data){
        console.log("session error: custom="+data); 
    });
    controller.send(id,"top\n\n");   
    console.log("just wait a  bit");
    setTimeout(function(){
        controller.close(id);
        console.log("######## all done ########");
    },5000);

    
}
catch(e)
{
    console.log("got: exception="+e);
}
