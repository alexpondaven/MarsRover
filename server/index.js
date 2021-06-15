// setting up HTTP server
const express = require("express");
const react = express();
react.use(express.json())
react.listen(3001, () => console.log("listening at port 3001"));
react.use(express.static("client"))

const app = express(); 
var cors = require('cors')
app.use(cors())
app.use(express.json())
app.listen(5000, () => console.log("listening at port 5000")); 
app.use(express.static("public"));
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
        // console.log(toboard)
    } else if (tmp.type === 'position'){
        toboard.mode = 1;
        toboard.position[0] = tmp.x;
        toboard.position[1] = tmp.y;
        // console.log(toboard)
    } else if (tmp.type === 'explore'){
        if (tmp.state) {
            toboard.mode = 2;
        } else {
            toboard.mode = 0;
            toboard.direction = new Uint8Array([0,0,0,0]);
        }
        // console.log(toboard)
    }
    response.json("Received");
    
})

app.get("/battery", (request, response) => {
    response.json({
        battery: battery,
        batteryusage: batteryusage,
        alert: batteryalert,
        mppt: mppt,
    })
})

app.get("/drive", (request, response) => {
    response.json({
        speed: speed,
        current: lastposition,
        obstacles: obstacles,
        alert: drivealert,
    })
})

const createCsvWriter = require('csv-writer').createObjectCsvWriter;
const csv = createCsvWriter({
    path: './data/roverpositions.csv',
    header: [
        {id: 'time', title: 'TIME'},
        {id: 'x', title: 'x'},
        {id: 'y', title:'y'}
    ]
});

app.get("/drivedata", (request, response) => {
    csv.writeRecords(roverposition)       
    .then(() => {
        console.log('...Done');
        response.download('./data/roverpositions.csv')
    });
})

const fs = require('fs')
app.get("/video", (request, response) => {
    var file;
    try {
        file = fs.readFileSync('bitmap.bmp')
    } catch (err) {
        // console.log(err);
        return;
    }
    var bmpData = bmp.decode(file);
    var rawData = bmp.encode(bmpData);
    base = Buffer.from(rawData.data).toString('base64')
    // console.log("done")

    response.json({
        bmp: base
    })
})

app.get("/videosetting/:color/:type", (request,response) => {
    var tmp = request.params;
    var rtn = null;
    for (let i=0; i<videocolor.length; i++){
        if (videocolor[i].color === tmp.color){
            rtn = videocolor[i]
        }
    }
    if (rtn === null) return;
    rtn = rtn[tmp.type];
    if (rtn === undefined) return;

    response.json({
        value: rtn
    })
})

var exposure = -1;
var gain = -1;
app.post("/videosetting", (request, response) => {
    var tmp = request.body;
    console.log(tmp);
    if (tmp.name === 'hsv'){
        for (let i=0; i<videocolor.length; i++){
            if (videocolor[i].color === tmp.color){
                let state = false;
                if (videocolor[i][tmp.type][0] === tmp.value[0]) state = true;

                videocolor[i][tmp.type] = tmp.value;
                let rtn = {
                    color: colortoint(tmp.color),
                    type: String(tmp.type[0]).toLowerCase(),
                    state: state,
                    value: tmp.value[state ? 1 : 0]
                }
                toboard.video += 1;
                toboard.videodetail.push(rtn);
            }
        }
    } else if (tmp.name === 'reset') {
        for (let i=0; i<videocolor.length; i++){
            if (videocolor[i].color === tmp.color){
                videocolor[i] = videocolordefault[i];
                console.log(videocolor[i])
            }
        }
    } else if (tmp.name === 'add') {
        if (tmp.type === 'exposure') {
            if (exposure === -1) {
                var rtn = {
                    color: 0,
                    type: 'e',
                    state: tmp.state,
                    value: 1,
                }
                exposure = toboard.video;
                toboard.video += 1;
                toboard.videodetail.push(rtn)
            } else {
                if (toboard.videodetail[exposure].state === tmp.state) {
                    toboard.videodetail[exposure].value += 1;
                } else if (toboard.videodetail[exposure].value === 1) {
                    toboard.videodetail.splice(exposure, 1);
                    gain = exposure > gain ? gain : (gain === -1 ? -1 : gain-1);
                    exposure = -1;
                    toboard.video -= 1;
                } else {
                    toboard.videodetail[exposure].value -= 1;
                }
            }
        } else if (tmp.type === 'gain') {
            if (gain === -1) {
                var rtn = {
                    color: 0,
                    type: 'g',
                    state: tmp.state,
                    value: 1,
                }
                gain = toboard.video;
                toboard.video += 1;
                toboard.videodetail.push(rtn)
            } else {
                if (toboard.videodetail[gain].state === tmp.state) {
                    toboard.videodetail[gain].value += 1;
                } else if (toboard.videodetail[gain].value === 1) {
                    toboard.videodetail.splice(gain, 1);
                    exposure = gain > exposure ? exposure : (exposure === -1 ? -1 : exposure-1);
                    gain = -1;
                    toboard.video -= 1;
                } else {
                    toboard.videodetail[gain].value -= 1;
                }
            }
        }
    }
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
const batteryalert = [
    {
        id:0,
        text: "Battery 2 fully charged"
    },
    {
        id:1,
        text: "Battery heating up"
    }
]
const mppt = require('./data/MPPT.js');
var lastposition = {x: 10, y:-1, time: new Date(), type: 'position'};
var roverposition = [lastposition];
var obstacles = [{
    x: 10, y: 0, time: new Date(), type: 'obstacle', color: 'red'
},{
    x: 4, y: -10, time: new Date(), type: 'obstacle', color: 'yellow'
}]
const drivealert = [
    {
        id:0,
        text: "Yellow obstacle 0.3m ahead"
    }
]
var base = '';
var toboard = {
    mode: 0,
    direction: new Uint8Array([0,0,0,0]),
    position: new Uint32Array([0,0]),
    video: 0,
    videodetail: []
}
const videocolordefault = [
    {
        color: 'red',
        Hue: [0,14],
        Saturation: [166,255],
        Value: [0,255],
    },
    {
        color: 'yellow',
        Hue: [32,53],
        Saturation: [144,255],
        Value: [0,255],
    },
    {
        color: 'pink',
        Hue: [0,14],
        Saturation: [51,174],
        Value: [96,255],
    },
    {
        color: 'blue',
        Hue: [128,255],
        Saturation: [0,96],
        Value: [16,176],
    },
    {
        color: 'green',
        Hue: [85,106],
        Saturation: [76,179],
        Value: [0,179],
    },
]
var videocolor = [
    {
        color: 'red',
        Hue: [0,14],
        Saturation: [166,255],
        Value: [0,255],
    },
    {
        color: 'yellow',
        Hue: [32,53],
        Saturation: [144,255],
        Value: [0,255],
    },
    {
        color: 'pink',
        Hue: [0,14],
        Saturation: [51,174],
        Value: [96,255],
    },
    {
        color: 'blue',
        Hue: [128,255],
        Saturation: [0,96],
        Value: [16,176],
    },
    {
        color: 'green',
        Hue: [85,106],
        Saturation: [76,179],
        Value: [0,179],
    },
]


// setting up TCP server 
var net = require('net');

const server = net.createServer(socket => {
    socket.on("data", data => {
        var tmp;
        try {
            tmp = JSON.parse(data.toString());
        } catch(e) { 
            return;
        }

        const relative = {
            color: tmp.colors,
            angle: tmp.angle,
            distance: tmp.distance
        };
        if (speed.angle===0 && tmp.position.direction===0){
            var slope = Math.atan((tmp.position.X-lastposition.x)/(tmp.position.Y-lastposition.y));
            slope = slope * 180 / Math.PI;
            var found = false;

            for (let i=0; i<relative.color.length; i++){
                if (relative.color[i] === -1 || relative.angle[i] === -1 || relative.distance[i] < 1) break;
                let theta = slope+relative.angle[i];
                theta = theta * Math.PI / 180;
                let tmp_pos = [Math.round(relative.distance[i]*Math.cos(theta)), Math.round(relative.distance[i]*Math.sin(theta))];

                for (let j=0; j<obstacles.length ; j++){
                    if (colortoint(obstacles[j].color) === relative.color[i]) {
                        found = true;
                        if (Math.abs(obstacles[j].x-tmp_pos[0]) < 50 && Math.abs(obstacles[j].y-tmp_pos[1]) < 50) {
                            // moving average of existing
                            obstacles[j].x = (obstacles[j].x+tmp_pos[0])/2;
                            obstacles[j].y = (obstacles[j].y+tmp_pos[1])/2;
                        } else {
                            // create new obstacle
                            let tmp = { x: tmp_pos[0], y: tmp_pos[1], time: new Date(), type: 'obstacle', color: obstacles[j].color};
                            obstacles.push(tmp);
                        }
                    }
                }
                if (!found) {
                    // create new obstacle 
                    let tmp = { x: tmp_pos[0], y: tmp_pos[1], time: new Date(), type: 'obstacle', color: colortoint(relative.color[i])};
                    obstacles.push(tmp);
                }
            }
        }
        
        if (lastposition.x !== tmp.position.X || lastposition.y !== tmp.position.Y){
            lastposition = {
                x: tmp.position.X,
                y: tmp.position.Y,
                time: new Date(),
                type: 'position',
            }
            roverposition.push(lastposition)
        }

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
        console.log(obstacles);

        
        var buf = Buffer.from(JSON.stringify(toboard));
        var tmp = Buffer.alloc(1, buf.length);
        buf = Buffer.concat([tmp,buf]);
        socket.write(buf);
        console.log("sent message: ", toboard);

        toboard.video = 0;
        toboard.videodetail = [];
        gain = -1;
        exposure = -1;
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
// const size = 77880;
// var datasize = 0;
// var databuffer = 0;

// const server_b = net.createServer(socket => {
//     socket.on("data", data => {
//         if (databuffer === 0){
//             databuffer = data
//         } else {
//             databuffer = Buffer.concat([databuffer,data]);
//         }
//         datasize += data.length;
//         if (datasize >= size){
//             socket.write("Received!");
//             console.log(datasize);
//             datasize =0;

//             var bmpData = bmp.decode(databuffer);
//             var rawData = bmp.encode(bmpData);
//             base = Buffer.from(rawData.data).toString('base64')

//             databuffer = 0;
//         }

//         socket.write("received!");
//     })

//     socket.on("error", error => {
//         console.log("client left")
//         if (error.message === 'read ECONNRESET') return;
//         console.log(error)
//     })

//     socket.on("end",() => {
//         console.log("client left")
//     })
// })
// server_b.listen(2002);

const colortoint = (str) => {
    switch(str){
        case 'red':
            return 1;
        case 'pink':
            return 2;
        case 'yellow':
            return 3;
        case 'green':
            return 4;
        case 'blue':
            return 5;
        default:
            return 0;
    }
}

const inttocolor = (int) => {
    switch(int){
        case 1:
            return 'red';
        case 2:
            return 'pink';
        case 3:
            return 'yellow';
        case 4:
            return 'green';
        case 5:
            return 'blue';
        default:
            return '';
    }
}