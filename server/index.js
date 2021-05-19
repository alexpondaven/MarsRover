// setting up HTTP server
const express = require("express");
const app = express(); 
var cors = require('cors')
app.use(cors())
app.use(express.json())
app.listen(5000, () => console.log("listening")); 
// respond with the data pack of battery and speed and 'hi'
app.get("/data", (request, response) => {
    response.json({
        data: 'hi',
        battery: battery,
        speed: speed
    });
});

app.post("/position", (request,response) => {
    var tmp = request.body;
    position[tmp.id] = tmp.state ? 1 : 0;
    console.log(position)
    response.json({
        data: 'hey'
    })
})

// database 
var battery = {
    status: false,
    remain : `34%`,
}
var speed = {
    speed : 57
}
var position = new Uint8Array(4);
for (let i=0; i<4; i++){
    position[i] = 0;
}

// setting up TCP server 
var net = require('net');

const server = net.createServer(socket => {
    // parse the received data and update database
    // reply with the 'position'
    socket.on("data", data => {
        console.log(data.toString())
        var tmp = parse(data.toString())
        if (tmp != null && tmp[0] == 'b'){
            battery.remain = String(tmp[1])+'%';
            console.log(battery);
        } else if (tmp != null && tmp[0] == 's'){
            speed.speed = tmp[1];
            console.log(speed)
        } else if (tmp != null && tmp[0] == 'bc'){
            battery.status = tmp[1];
            console.log(battery);
        }

        socket.write(position)
    })

    socket.on("end",() => {
        console.log("client left")
    })
})
server.listen(2000);

function parse(str){
    if (str[0] == 'b' && str[1] == 'c'){
        for (var i=2; i<str.length; i++){
            if (str[i] == 'c') {
                return ['bc',true]
            } else if (str[i] == 'n') {
                return ['bc',false]
            }
        }
        return null
    }else if (str[0] == 'b'){
        for (var i =0; i<str.length; i++){
            // treat 0-9 . - as a start of number
            if ((str.charCodeAt(i) > 47 && str.charCodeAt(i) < 58) || (str[i] == '.') || (str[i] == '-') ){
                var tmp = Number(str.slice(i));
                if (isNaN(tmp)){
                    return null;
                } else {
                    return ['b',tmp];
                }
            }
        }
    } else if (str[0] == 's'){
        for (var i =0; i<str.length; i++){
            // treat 0-9 . - as a start of number
            if ((str.charCodeAt(i) > 47 && str.charCodeAt(i) < 58) || (str[i] == '.') || (str[i] == '-') ){
                var tmp = Number(str.slice(i));
                if (isNaN(tmp)){
                    return null;
                } else {
                    return ['s',tmp];
                }
            }
        }
    }
    return null;
}