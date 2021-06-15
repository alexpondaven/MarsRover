import ReactSpeedometer from "react-d3-speedometer"
import { Link } from 'react-router-dom'

function Speed({speed}) {
    return (
        <Link to="/speed" style={{ textDecoration: 'none'}} >
        <div 
            className='HomeBlock'         
        >
            <h2>SPEED</h2>
            <p1>
            </p1>
            <div style={{ width: 300, height: 200 }}>
                <ReactSpeedometer
                    maxValue={100}
                    value={speed.speed}
                    needleColor="red"
                    segments={10}
                    startColor="#33CC33"
                    endColor="#FF471A"

                />
            </div>
       </div>
       </Link>
    )
}

export default Speed
