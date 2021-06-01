import { useState, useEffect, Component } from 'react'

import Battery from '../Components/BatteryPage_Battery.js'
import Health from '../Components/BatteryPage_Health.js'
import Alerts from '../Components/Alerts.js'
import Linechart from '../Components/Linechart.js'

function BatteryPage({battery}) {
    const [batteries,setBattery] = useState([battery]);
    const [data,setData] = useState();
    const [alerts,setAlerts] = useState([]);

    function update(response) {
        setData(response.batteryusage);
        setBattery([response.battery])
        setAlerts(response.alert)
    }

    const getData = async() => {
        fetch('http://localhost:5000/battery')
          .then(response => response.json())
          .then(response => update(response))
    }

    useEffect(() => {
        getData();
        setInterval(getData, 1000)
    });

    return (
        <div className="SubPage">
            <div className="LeftColumn" >
                <div className="Card0">
                    <h3>BATTERY</h3>
                    <p1>some properties to be added</p1>
                </div>
                <Alerts alerts={alerts} />
            </div>

            <div className="RightColumn">

                <div style={{ display: 'flex' }}>
                    {batteries.map(battery =>
                        <Battery battery={battery} />
                    )}

                    {batteries.map(battery =>
                        <Health battery={battery} />
                    )}
                </div>

                <Linechart data={data} name="Battery Usage" />

            </div>

        </div>
    )
}

export default BatteryPage
