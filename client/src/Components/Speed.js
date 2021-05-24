import ReactSpeedometer from "react-d3-speedometer"
import { Link } from 'react-router-dom'

function Speed({speed}) {
    return (
        <Link to="/speed" style={{ textDecoration: 'none'}} >
        <card 
            className='Speed'         
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
       </card>
       </Link>
    )
}

export default Speed
