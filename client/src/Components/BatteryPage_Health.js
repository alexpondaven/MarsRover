import { CircularProgressbar, buildStyles } from 'react-circular-progressbar'

function Health({battery}) {
    const x = battery.health.slice(0,-1);

    return (
        <div className="Card1">
            <h4>
                HEALTH
            </h4>
            <div style={{ width: 200, height: 200 }}>
                <CircularProgressbar
                    value={x} text={battery.health}
                    styles={buildStyles({
                        pathColor: `rgba(62, 152, 199, ${x})`,
                        textColor: '#000000',
                        trailColor: '#d6d6d6',
                        backgroundColor: '#3e98c7',
                        pathTransitionDuration: 0.5,
                    })}
                />
            </div>
        </div>
    )
}

export default Health
