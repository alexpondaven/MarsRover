var lastposition = {x: 0, y:0, time: new Date(), type: 'position'};
var roverposition = [lastposition];
var speed = {
    speed: 0,
    direction: 0,
}
var obstacle = [];

const toboard = {
    mode: 0,
    direction: new Uint8Array([0,0,0,0]),
    position: new Uint32Array([0,0]),
    video: 0,
    videodetail: []
}

const net = require('net');
var state = false;

const server = net.createServer(socket => {
    console.log("connected");
    socket.on("data", data => {
        var tmp;
        var databuf;
        console.log(data.toString() + " " + data.length)
        try {
            tmp = JSON.parse(data.toString());
            if (state) {
                databuf += data;
                tmp = JSON.parse(databuf.toString());
            }
        } catch(e) { 
            console.log(e)
            state = true;
            databuf = data;
            return;
        }
        if (tmp.distance.length != 5) {
            console.log("distance length 5")
            state = true;
            databuf = data;
            return;
        }
        state = false;
        
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
        speed.direction = tmp.position.direction;

        obstacle = [tmp.colors,tmp.angle,tmp.distance];
        console.log(obstacle);
        file.write(tmp.colors.join(', ')+ '\t' + tmp.angle.join(', ') + '\t' + tmp.distance.join(', '))
        
        var buf = Buffer.from(JSON.stringify(toboard));
        var tmp = Buffer.alloc(1, buf.length);
        buf = Buffer.concat([tmp,buf]);
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

const readline = require("readline");
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});
const fs = require('fs');
const { exit } = require('process');
var file = fs.createWriteStream('data.txt');

var recursiveAsyncReadLine = function () {
    rl.question('', function (answer) {
        if (answer === "end") {
            // fs.writeFile('data.txt', obstacle)
            file.end();
            exit()
        } else if (answer === "start") {
            toboard.mode = 2;
        } else if (answer === "stop") {
            toboard.mode = 0;
        }
        
        recursiveAsyncReadLine(); 
    });
};
recursiveAsyncReadLine();