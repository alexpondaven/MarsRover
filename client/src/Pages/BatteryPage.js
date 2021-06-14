import { useState, useEffect } from 'react'

import Battery from '../Components/BatteryPage_Battery.js'
// import Health from '../Components/BatteryPage_Health.js'
import Power from '../Components/BatteryPage_Power.js'
import Alerts from '../Components/Alerts.js'
// import Linechart from '../Components/Linechart.js'
import Graph from '../Components/BatteryPage_Graph.js'

function BatteryPage() {
    const [batteries,setBattery] = useState([{
        status: true,
        remain : '34%',
        health: '30%',
      }
    ]);
    const [data1,setData1] = useState([]);
    const [data2,setData2] = useState([]);
    const [mppt,setMPPT] = useState([]);
    const [alerts,setAlerts] = useState([]);

    function update(response) {
        setData1(response.batteryusage.data1);
        setData2(response.batteryusage.data2);
        setMPPT(response.mppt)
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
        setInterval(getData, 5000)
    },[]);

    return (
        <div className="SubPage">
            <div className="LeftColumn" >
                <div className="Card0">
                    <h3>BATTERY</h3>
                    <p>some properties to be added</p>
                </div>
                <Alerts alerts={alerts} />
            </div>

            <div className="RightColumn">

                <div style={{ display: 'flex' }}>
                    {batteries.map((battery,index) =>
                        <Battery key={index} battery={battery} />
                    )}

                    {batteries.map((battery,index) =>
                        <Power key={index} battery={battery} />
                    )}  
                </div>

                <Graph data1={data1} data2={data2} mppt={mppt}/>

            </div>

        </div>
    )
}

export default BatteryPage
