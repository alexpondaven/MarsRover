console.log("listening")
var timeinterval = 500;
var i = 4;

// setting up TCP server 
var net = require('net');

const server = net.createServer(socket => {
    // parse the received data and update database
    // reply with the 'position'
    socket.on("data", data => {
        console.log(data.toString())
        
        socket.write(position)
    })

    socket.on("end",() => {
        console.log("client left")
    })
})
server.listen(2000);

var position = new Uint8Array([0,0,0,0]);

const update = function() {
    if (i !=4){
        position[i] = 0;
    } 
    i = Math.floor(Math.random()*5);
    if (i != 4){
        position[i] = 1;
    }
    timeinterval = Math.floor(Math.random()*10+1)*100; // 100-1000
    // console.log(position + " " + timeinterval)
    setTimeout(update,timeinterval);
}
update();