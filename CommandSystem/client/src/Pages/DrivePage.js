import { useState, useEffect, Component } from 'react'

import Map from '../Components/Map.js'
import Speed from '../Components/DrivePage_Speed.js'
import Steering from '../Components/DrivePage_Steering.js'
import Alerts from '../Components/Alerts.js'

function DrivePage() {
    const [speeds,setSpeed] = useState([
        {
          speed : 43,
          angle : 0
        }
      ]);
    const [positions,setPosition] = useState([]);
    const [currentposition, setCurrent] = useState([]);
    const [obstacles,setObstacle] = useState([]);
    const [alerts,setAlerts] = useState([]);

    useEffect(() => {
        getData();
        setInterval(getData,5000)
    },[])

    function update(response) {
        setSpeed([response.speed]);
        if (currentposition !== [response.current]){
            setPosition(positions => [...positions, response.current]);
        }
        setCurrent([response.current]);
        setObstacle(response.obstacles);
        setAlerts(response.alert);
    }

    const getData = async() => {
        fetch('http://localhost:5000/drive')
          .then(response => response.json())
          .then(response => update(response) )
    }

    const onClick = () => {
        setPosition(currentposition);
    }

    return (
        <div className="SubPage">
            <div className="LeftColumn" >
                <div className="Card0">
                    <h3>DRIVE</h3>
                    <p style={{fontSize: '17px'}}>
                        The rover runs on 2 wheels, controlled separately by 2 motors. 
                        It can turn by moving the 2 wheels in opposite direction.
                        <br/>
                        <br/>
                        An optical flow sensor is also used to measure the travelling distance in x and y direction, and estimate the coordinate
                        of the rover.
                    </p>
                </div>
                <Alerts alerts={alerts} />
            </div>

            <div className="RightColumn">

                <div style={{ display: 'flex' }}>
                    {speeds.map((speed,index) =>
                        <Speed key={index} speed={speed} />
                    )}

                    {speeds.map((speed,index) =>
                        <Steering key={index} speed={speed} />
                    )}
                    
                </div>

                <div className="Card3">
                    <h3>Map</h3>
                    <button className="ClearButton" style={{margin: '30px 100px'}}>
                    <a  
                        style={{textDecoration: 'none', color: '#000'}}
                        href='http://localhost:5000/drivedata' download
                    >
                        Download
                    </a>
                    </button>
                    <button className="ClearButton" onClick={onClick}>Clear</button>
                    <div className="Map">
                        <Map positions={positions} current={currentposition} obstacles={obstacles} />
                    </div>
                </div>

            </div>

        </div>
    )
}

export default DrivePage
