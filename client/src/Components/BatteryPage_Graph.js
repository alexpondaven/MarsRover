import ReactCardFlip from 'react-card-flip';
import { useState, useEffect } from 'react'

import Linechart from './Linechart.js'

function Graph({data1,data2,mppt}) {
    const [flip,setFlip] = useState(false);
    const onClick = () => {
        setFlip(!flip);
    }

    return (
        <div className="Card3">
            <ReactCardFlip isFlipped={flip} flipDirection="vertical">
                <div>
                    <Linechart data1={data1} name1='Battery 1' data2={data2} name2='Battery2' name="Battery Usage" limit={true}/>
                    <button onClick={onClick} style = {{
                        position: 'absolute',
                        top: '0px',
                        right: '0px'
                    }}>
                        MPPT vs Voltage
                    </button>
                </div>

                <div>
                    <Linechart data1={mppt} name1='MPPT' name="MPPT vs Voltage" limit={false}/>
                    <button onClick={onClick} style = {{
                        position: 'absolute',
                        top: '0px',
                        right: '0px'
                    }}>
                        Battery Usage
                    </button>
                </div>
            </ReactCardFlip>
        </div>
    )
}

export default Graph
