import { useState,useEffect } from 'react'
import ReactApexChart from "react-apexcharts"

function Power({data,battery}) {
    const [tmp_data,setData] = useState([{
        name: 'Voltage',
        data: [3308.61,3324.52]
    }])
    const [bat,setbat] = useState([3308.61,3324.52])
    const state = {
        series: tmp_data,
        options : {
            chart: {
                height: '80vh',
                type: 'bar',
            },
            xaxis: {
                categories: ['Battery 1', 'Battery 2'],
            }
        }
    }

    const update = () => {
        setData([{
            name: 'Voltage',
            data: [3320.54,3332.47]
        }])
        setbat([3320.54,3332.47])
    }

    useEffect(() => {
        setInterval(update,5000)
    },[]) 

    return (
        <div className="Card1" style={{textAlign: 'left'}}>
            <h3>{battery.status ? "Input" : "Output"}</h3>
            <div style={{display: 'grid'}}> 
                <div style={{marginLeft: '30px'}}>
                    <h4> Battery 1: {bat[0]}mV</h4> 
                    <h4> Battery 2: {bat[1]}mV</h4>'
                    
                </div>
                <div style={{position: 'absolute', bottom:'10px', right: '0px', marginRight: '50px', width: '50%', height: '80%'}}>
                    <ReactApexChart options={state.options} series={state.series} type="bar" height='100%' width='100%'/>
                </div>
            </div>
        </div>
    )
}

export default Power
