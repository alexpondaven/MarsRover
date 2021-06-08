import { useState } from 'react'
import Map from '../Components/Map.js'

function ControllerPosition({positions, currentposition, obstacles, explore, onClickExplore}) {
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

    const postDataPos = async() => {
        if (explore) onClickExplore();
        var body = {
            type: 'position',
            x: command.x,
            y: command.y
        }
        fetch('http://localhost:5000/position', {
          method: 'POST',
          headers: {
            'Content-type': 'application/json',
          },
          body: JSON.stringify(body),
        })
    }

    const onSubmit = (event) => {
        event.preventDefault();
        if (err === "") {
            alert("Coordinate (" + command.x + "," + command.y + ") is submitted");
            postDataPos();
        }
    }


    return (
        <div className="PositionControl">
            <div style={{border: '1px solid black', width: '100%'}}>
                <Map positions={positions} current={currentposition} obstacles={obstacles} command={[command]}/>
            </div>
            <form onSubmit={onSubmit}>
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
                <input
                    type='submit'
                />
            </form>
        </div>
    )
}

export default ControllerPosition
