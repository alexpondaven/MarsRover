import ReactSpeedometer from "react-d3-speedometer"

function Speed({speed}) {
    return (
        <div className="Card1">
            <h4>SPEED</h4>
            
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
    )
}

export default Speed
