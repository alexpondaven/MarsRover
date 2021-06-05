import { useState, useEffect, Component } from 'react'

import Map from '../Components/Map.js'
import Speed from '../Components/DrivePage_Speed.js'
import Steering from '../Components/DrivePage_Steering.js'
import Alerts from '../Components/Alerts.js'

function DrivePage({speed}) {
    const [speeds,setSpeed] = useState([speed]);
    const [positions,setPosition] = useState([]);
    const [currentposition, setCurrent] = useState([]);
    const [obstacles,setObstacle] = useState([]);
    const [alerts,setAlerts] = useState([]);

    useEffect(() => {
        getData();
        setInterval(getData,1000)
    })

    function update(response) {
        setSpeed([response.speed]);
        setPosition(response.position);
        setCurrent(response.current);
        setObstacle(response.obstacles);
        setAlerts(response.alert);
    }

    const getData = async() => {
        fetch('http://localhost:5000/drive')
          .then(response => response.json())
          .then(response => update(response))
    }

    return (
        <div className="SubPage">
            <div className="LeftColumn" >
                <div className="Card0">
                    <h3>DRIVE</h3>
                    <p1>some properties to be added</p1>
                </div>
                <Alerts alerts={alerts} />
            </div>

            <div className="RightColumn">

                <div style={{ display: 'flex' }}>
                    {speeds.map(speed =>
                        <Speed speed={speed} />
                    )}

                    {speeds.map(speed =>
                        <Steering speed={speed} />
                    )}
                    
                </div>

                <div className="Card3">
                    <h3>Map</h3>
                    <div className="Map">
                        <Map positions={positions} current={currentposition} obstacles={obstacles} />
                    </div>
                </div>

            </div>

        </div>
    )
}

export default DrivePage
