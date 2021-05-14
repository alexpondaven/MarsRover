// setting up server
const express = require("express");
const app = express(); 
var cors = require('cors')
app.use(cors())
app.listen(5000, () => console.log("listening")); 
app.get("/hi", (request, response) => {
    response.json({
        data: 'hi',
        battery: battery,
        speed: speed
    });
});

var battery = {
    status: false,
    remain : `34%`,
}
var speed = {
    speed : 57
}

// read from command line
const readline = require("readline");
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});
var recursiveAsyncReadLine = function () {
    rl.question('updates? ', function (answer) {
        var tmp = parse(answer);
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
        recursiveAsyncReadLine(); 
    });
};
recursiveAsyncReadLine();

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