import { CircularProgressbar,buildStyles } from 'react-circular-progressbar'
import { Link } from 'react-router-dom'

function Battery({battery}) {
    const x = battery.remain.slice(0,-1);

    return (
        <Link to="/battery" style={{ textDecoration: 'none' , textColor: 'black'}} >
        <card 
            className='HomeBlock' 
            style={{ backgroundColor: battery.status ? 'rgb(70,225,70)' : 'rgb(221, 96, 96)' }}
        >
            <h2 className='card-title'>BATTERY</h2>
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
                        pathTransitionDuration: 0.5,
                    })}
                />
            </div>
       </card>
       </Link>
    )
}

export default Battery
