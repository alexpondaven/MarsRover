# Mars Rover Command Subsystem
The Command Subsystem consists of a client and server, which is run with React framework and Node.js respectively.

## Overview
The server would be set up on `https://localhost:5000` and the client (React dev server) would be set up on `https://localhost:3000` <br/>
Going to `https://localhost:3000` on the web browser after setting up both servers would show you 
![title](images/webpage.png) <br>
The two cards show information about the battery and speed represented on different meters. 

## Usage
`Node.js` is required to be installed for running the script. It can be downloaded from `https://nodejs.org/en/`
### Install Dependencies for Server
```
cd server 
npm install express 
npm install cors --save 
npm install readline
```
### Run the Node.js Server
```
cd server
node index.js
```
### Install Dependencies for Client
```
cd client
npm install --save react-circular-progressbar
npm install --save react-d3-speedometer
```
### Run the React dev Client Server
``` 
cd client
npm start
```
*This is currently still in development mode. In the final product, separately starting up of the React dev Server would not be needed.

## React Client
React is chosen as the front-end framework due to its largely supported libraries and community. Also its DOM and state property. 

`src/App.js` contains the "main framework" of the webpage. <br/>
`src/Components` folder contains Javascript files for components called in `src/App.js` which are also written in React. 

Data is fetched from the server (`https://localhost:5000/hi`)every 1 second and dynamically updates the webpage without reloading. 

## Node.js Server
Node.js is chosen as the back-end server. It establishs a server at port 5000 (`https://localhost:5000`). Data packet containing information on Battery and Speed would be returned if there is a fetch at subpage `/hi` (which is done under the hood)

The server takes in command line input for testing currently, which would update its database on Battery and Speed, and reflected on the client webpage.

Input in the following format: <br/>
* battery charge: `b` + { number ∈ (0,100) }
* battery charging status: `bc` + {`c`(charging)||`n`(not charging)} 
* speed: `s` + { number ∈ (0,100) }

An updated database would be printed out in the command line after a valid input.


## Future Development
1. Add socket for communication with the control subsystem
2. Add components for manual remote control
3. Video streaming

## Change Log
14-May-2021: initial commit