import ReactSpeedometer from "react-d3-speedometer"

function Speed({speed}) {
    return (
        <div 
            className='Battery'         
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
                />
            </div>
       </div>
    )
}

export default Speed
