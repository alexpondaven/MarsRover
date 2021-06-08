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
    socket.on("data", data => {
        console.log(JSON.parse(data.toString()))
        var tmp = JSON.parse(data.toString());

        if (lastposition.x !== tmp.position.X || lastposition.y !== tmp.position.Y){
            lastposition = {
                x: tmp.position.X,
                y: tmp.position.Y,
                time: new Date(),
                type: 'position',
            }
            roverposition.push(lastposition)
        }
        console.log(roverposition);

        speed.speed = tmp.position.speed;
        switch(tmp.position.direction) {
            case 0:
                speed.angle = 0;
                break;
            case 1:
                speed.angle = 180;
                break;
            case 2:
                if (speed.angle === -175) ;
                else if (speed.angle < 0) speed.angle -= 5;
                else speed.angle = -5;
                break;
            case 3:
                if (speed.angle === 175) ;
                else if (speed.angle > 0) speed.angle += 5;
                else speed.angle = 5;
                break;
        }
        console.log(speed)
        
        var buf = Buffer.from(JSON.stringify(toboard));
        socket.write(buf);
    })

    socket.on("error", error => {
        console.log("client left")
        if (error.message === 'read ECONNRESET') return;
        console.log(error)
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

    socket.on("error", error => {
        console.log("client left")
        if (error.message === 'read ECONNRESET') return;
        console.log(error)
    })

    socket.on("end",() => {
        console.log("client left")
    })
})
server_b.listen(2001);