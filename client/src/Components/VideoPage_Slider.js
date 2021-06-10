import { useState, useEffect } from 'react'

import Tooltip from "@material-ui/core/Tooltip";
import Slider from '@material-ui/core/Slider';

function Video_Slider({name, color, onChange, forcefetch, tooltip}) {
    const [value, setValue] = useState([]);

    const handleChange = (event, newValue) => {
        setValue(newValue);
    };

    const onChangeCommitted = (event, newValue) => {
        setValue(newValue);
        onChange(name,newValue);
    };

    const update = (response) => {
        setValue(response.value)
    }

    const getData = () => {
        fetch('http://localhost:5000/videosetting/' + color + '/' + name)
            .then(response => response.json())
            .then(response => update(response))
    }

    useEffect(() => {
        getData();
    },[color,forcefetch])

    return (
        <div style={{ width: '400px'}}>
            <Tooltip title={tooltip}>
                <h4 style={{fontFamily: 'Roboto'}}>{name}</h4>
            </Tooltip>

            <div >
                <Slider
                    value={value}
                    onChange={handleChange}
                    onChangeCommitted={onChangeCommitted}
                    valueLabelDisplay="auto"
                    aria-labelledby="range-slider"
                    min={0}
                    max={255}
                />
            </div>
        </div>
    )
}

export default Video_Slider
