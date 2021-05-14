import { CircularProgressbar,buildStyles } from 'react-circular-progressbar'

function Battery({battery}) {
    const x = battery.remain.slice(0,-1);

    return (
        <div 
            className='Battery' 
            style={{ backgroundColor: battery.status ? 'rgb(70,225,70)' : 'rgb(221, 96, 96)' }}
        >
            <h2>BATTERY</h2>
            <p1>
                STATUS:{battery.status ? 'Charging' : 'Not Charging'}
                <br/>
                ESTIMATED TIME: NA
            </p1>
            <div style={{ width: 200, height: 200 }}>
                <CircularProgressbar 
                    value={x} text={battery.remain} 
                    styles={ buildStyles({
                        pathColor: `rgba(62, 152, 199, ${x})`,
                        textColor: '#000000',
                        trailColor: '#d6d6d6',
                        backgroundColor: '#3e98c7',
                    })}
                />
            </div>
       </div>
    )
}

export default Battery
