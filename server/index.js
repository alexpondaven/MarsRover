// setting up HTTP server
const express = require("express");
const app = express(); 
var cors = require('cors')
app.use(cors())
app.use(express.json())
app.listen(5000, () => console.log("listening")); 
app.use(express.static("public"));
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
    if (tmp.type === 'direction'){
        toboard.mode = 0;
        toboard.direction[tmp.id] = tmp.state ? 1 : 0;
        console.log(toboard)
    } else if (tmp.type === 'position'){
        toboard.mode = 1;
        toboard.position[0] = tmp.x;
        toboard.position[1] = tmp.y;
        console.log(toboard)
    } else if (tmp.type === 'explore'){
        if (tmp.state) {
            toboard.mode = 2;
        } else {
            toboard.mode = 0;
            toboard.direction = new Uint8Array([0,0,0,0]);
        }
        console.log(toboard)
    }
    
})

app.get("/battery", (request, response) => {
    response.json({
        battery: battery,
        batteryusage: batteryusage,
        alert: batteryalert
    })
})

app.get("/drive", (request, response) => {
    response.json({
        speed: speed,
        position: roverposition,
        current: [lastposition],
        obstacles: obstacles,
        alert: batteryalert,
    })
})

app.get("/test", (request, response) => {
    response.json({
        bmp: base
    })
})

// database 
var battery = {
    status: false,
    remain: '34%',
    health: '50%'
}
var speed = {
    speed : 57,
    angle : 0
}
var batteryusage = require('./data/SoC_t.js');
var batteryalert = [
    {
        id:0,
        text: "hi"
    },
    {
        id:1,
        text: "world"
    }
]
var lastposition = {x: 10, y:-1, time: new Date(), type: 'position'};
var roverposition = [lastposition];
var obstacles = [{
    x: 10, y: 0, time: new Date(), type: 'obstacle'
},{
    x: 4, y: -10, time: new Date(), type: 'obstacle'
}]
var base = '';
var toboard = {
    mode: 0,
    direction: new Uint8Array([0,0,0,0]),
    position: new Uint32Array([0,0])
}

// var data;

// const request = require('request');
// request('https://api.nasa.gov/insight_weather/?api_key=DEMO_KEY&feedtype=json&ver=1.0', function (error, response, body) {
//     data = JSON.parse(body).validity_checks;
//     var tmp = data.sols_checked;
//     tmp = tmp[0];
//     console.log(data, tmp);
//     console.log(data[tmp]);
// });

// setting up TCP server 

var net = require('net');

const server = net.createServer(socket => {
    // parse the received data and update database
    // reply with the 'position'
    socket.on("data", data => {
        console.log(data.toString())
        var tmp = parse(data.toString())
        if (tmp != null && tmp[0] == 'b'){
            battery.remain = String(tmp[1])+'%'
            console.log(battery);
        } else if (tmp != null && tmp[0] == 's'){
            speed.speed = tmp[1];
            console.log(speed)
        } else if (tmp != null && tmp[0] == 'bc'){
            battery.status = tmp[1];
            console.log(battery);
        } else if (tmp != null && tmp[0] == 'h'){
            battery.health = String(tmp[1])+'%';
            console.log(battery);
        } else if (tmp != null && tmp[0] == 'x'){
            lastposition = {
                x: tmp[1],
                y: lastposition.y,
                time: new Date(),
                type: 'position'
            }
            roverposition.push(lastposition);
            console.log(roverposition);
        } else if (tmp != null && tmp[0] == 'y'){
            lastposition = {
                x: lastposition.x,
                y: tmp[1],
                time: new Date(),
                type: 'position'
            }
            roverposition.push(lastposition);
            console.log(roverposition);
        } else if (tmp != null && tmp[0] == 'a'){
            speed.angle = tmp[1];
            console.log(speed);
        }

        var buf = Buffer.from(JSON.stringify(toboard));
        socket.write(buf);
    })

    socket.on("end",() => {
        console.log("client left")
    })
})
server.listen(2000);

// TCP socket for video streaming
const bmp = require("bmp-js");
const size = 77880;
var datasize = 0;
var databuffer = 0;

const server_b = net.createServer(socket => {
    socket.on("data", data => {
        if (databuffer === 0){
            databuffer = data
        } else {
            databuffer = Buffer.concat([databuffer,data]);
        }
        datasize += data.length;
        if (datasize >= size){
            socket.write("Received!");
            console.log(datasize);
            datasize =0;

            var bmpData = bmp.decode(databuffer);
            var rawData = bmp.encode(bmpData);
            base = Buffer.from(rawData.data).toString('base64')

            databuffer = 0;
        }

        socket.write("received!");
    })

    socket.on("end",() => {
        console.log("client left")
    })
})
server_b.listen(2001);

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
    }else if (str[0] == 'h'){
        for (var i =0; i<str.length; i++){
            // treat 0-9 . - as a start of number
            if ((str.charCodeAt(i) > 47 && str.charCodeAt(i) < 58) || (str[i] == '.') || (str[i] == '-') ){
                var tmp = Number(str.slice(i));
                if (isNaN(tmp)){
                    return null;
                } else {
                    return ['h',tmp];
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
    } else if (str[0] == 'x'){
        for (var i =0; i<str.length; i++){
            // treat 0-9 . - as a start of number
            if ((str.charCodeAt(i) > 47 && str.charCodeAt(i) < 58) || (str[i] == '.') || (str[i] == '-') ){
                var tmp = Number(str.slice(i));
                if (isNaN(tmp)){
                    return null;
                } else {
                    return ['x',tmp];
                }
            }
        }
    } else if (str[0] == 'y'){
        for (var i =0; i<str.length; i++){
            // treat 0-9 . - as a start of number
            if ((str.charCodeAt(i) > 47 && str.charCodeAt(i) < 58) || (str[i] == '.') || (str[i] == '-') ){
                var tmp = Number(str.slice(i));
                if (isNaN(tmp)){
                    return null;
                } else {
                    return ['y',tmp];
                }
            }
        }
    } else if (str[0] == 'a'){
        for (var i =0; i<str.length; i++){
            // treat 0-9 . - as a start of number
            if ((str.charCodeAt(i) > 47 && str.charCodeAt(i) < 58) || (str[i] == '.') || (str[i] == '-') ){
                var tmp = Number(str.slice(i));
                if (isNaN(tmp)){
                    return null;
                } else if (tmp < 180 && tmp > -180) {
                    return ['a',tmp];
                } else {
                    return null;
                }
            }
        }
    } 
    return null;
}