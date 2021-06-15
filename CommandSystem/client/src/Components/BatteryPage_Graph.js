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
                    <Linechart type = {true} data1={data1} data2={data2}  name="Battery Usage" />
                    <button onClick={onClick} style = {{
                        position: 'absolute',
                        top: '0px',
                        right: '0px'
                    }}>
                        MPPT vs Voltage
                    </button>
                </div>

                <div>
                    <Linechart type={false} data1={mppt} name="Power vs Voltage" />
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
