import { useState, useEffect } from 'react'
import Map from '../Components/Map.js'

function ControllerPosition({explore, setExplore}) {
    const [positions,setRover] = useState([]);
    const [currentposition, setCurrent] = useState([]);
    const [obstacles,setObstacle] = useState([]);

    var current_var = null;

    function update(response) {
        if (current_var === null || current_var.x !== response.current.x || current_var.y !== response.current.y){
            setRover(positions => [...positions, response.current]);
            current_var = response.current;
        }
        setCurrent([response.current]);
        setObstacle(response.obstacles);
    }

    const getData = async() => {
        fetch('http://localhost:5000/drive')
          .then(response => response.json())
          .then(response => update(response) )
    }

    useEffect(() => {
        getData();
        setInterval(getData,10000)
    },[])

    const [command, setCommand] = useState({
        x: 0,
        y: 0,
        time: new Date(),
        type: 'command'
    });
    const [err, setErr] = useState("");

    const onChangeX = (event) => {
        if (isNaN(Number(event.target.value)) && event.target.value !== '-') {
            setErr("Please enter a number");
        } else if (event.target.value === "") {
            setCommand({
                x: 0,
                y: command.y,
                time: new Date(),
                type: 'command'
            });
            setErr("");
        } else {
            setCommand({
                x: Math.round(event.target.value),
                y: command.y,
                time: new Date(),
                type: 'command'
            });
            setErr("");
        }
    }

    const onChangeY = (event) => {
        if (isNaN(Number(event.target.value)) && event.target.value !== '-') {
            setErr("Please enter a number");
            setCommand();
        } else if (event.target.value === "") {
            setCommand({
                x: command.x,
                y: 0,
                time: new Date(),
                type: 'command'
            });
            setErr("");
        } else {
            setCommand({
                x: command.x,
                y: Math.round(event.target.value),
                time: new Date(),
                type: 'command'
            });
            setErr("");
        }
    }

    var bodypos;
    const postDataPos = async() => {
        if (explore) setExplore(false);
        bodypos = {
            type: 'position',
            x: command.x,
            y: command.y
        }
        fetch('http://localhost:5000/position', {
          method: 'POST',
          headers: {
            'Content-type': 'application/json',
          },
          body: JSON.stringify(bodypos),
        })
    }

    const onStop = () => {
        var body = {
            type: 'explore',
            state: false
        }
        fetch('http://localhost:5000/position', {
          method: 'POST',
          headers: {
            'Content-type': 'application/json',
          },
          body: JSON.stringify(body),
        })
        alert("Rover stopped")
    }

    const onSubmit = (event) => {
        event.preventDefault();
        if (err === "") {
            alert("Coordinate (" + command.x + "," + command.y + ") is submitted");
            postDataPos(command.x,command.y);
        }
    }

    const onClear = () => {
        setRover(currentposition);
    }


    return (
        <div className="PositionControl">
            <div style={{border: '1px solid black', width: '100%'}}>
                <Map positions={positions} current={currentposition} obstacles={obstacles} command={[command]}/>
            </div>
            <div style={{position: 'relative'}}>
                <button className="ClearButton" style={{margin: '5px'}}onClick={onClear}>Clear</button>
            </div>
            <div style={{marginTop: '30px'}}>
                <h4>Please enter the target coordinate: </h4>
                <div style={{display: 'flex'}}>   
                    <form> 
                        <p>x:</p>
                        <input
                            type="text"
                            onChange={onChangeX}
                        />
                    </form>
                    <form> 
                        <p>y:</p>
                        <input
                            type="text"
                            onChange={onChangeY}
                        />
                    </form>
                </div>

                <p1 style={{ color: 'red', fontFamily: 'sans-serif', fontSize: 'small' }}>{err}</p1>

                <br/>
                <button onClick={onStop} style={{width: '60px', margin: '10px'}}>Stop</button>
                <button onClick={onSubmit} style={{width: '60px', margin: '10px'}}>Submit</button>
            </div>
        </div>
    )
}

export default ControllerPosition