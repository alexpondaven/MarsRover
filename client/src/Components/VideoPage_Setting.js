import { useState, useEffect } from 'react'

import { makeStyles } from '@material-ui/core/styles';
import Button from '@material-ui/core/Button';
import ButtonGroup from '@material-ui/core/ButtonGroup';
import MenuItem from '@material-ui/core/MenuItem';
import Select from '@material-ui/core/Select';
import Tooltip from "@material-ui/core/Tooltip";

import { AiOutlineClose, AiOutlineInfoCircle } from 'react-icons/ai';
import { IconContext } from 'react-icons';

import VideoPage_Sliders from '../Components/VideoPage_Sliders.js'

const useStyles = makeStyles(() => ({
    buttongroup: {
        margin: 'auto',
        alignItems: 'center',
        textAlign: 'center',
        display: 'flex'
    },
    button: {
        // margin: 'auto',
        textAlign: 'center',
        display: 'flex'
    },
    select: {
        padding: '0px 10px',
        fontSize: '20px',
        fontFamily: 'Roboto',
        },
    }));

function VideoPage_Setting({setState}) {
    const [color,setColor] = useState('red')
    const classes = useStyles(color);

    const onChange = (event) => {
        setColor(event.target.value);
        console.log(event.target.value);
    }

    const onClick = (str,bool) => {
        let body = {
            name: 'add',
            type: str,
            state: bool
        }
        fetch('http://localhost:5000/videosetting', {
          method: 'POST',
          headers: {
            'Content-type': 'application/json',
          },
          body: JSON.stringify(body),
        })
    }

    const [forcefetch, setFetch] = useState(false);

    const onReset = (color) => {
        let body = {
            name: 'reset',
            color: color
        }
        fetch('http://localhost:5000/videosetting', {
          method: 'POST',
          headers: {
            'Content-type': 'application/json',
          },
          body: JSON.stringify(body),
        })
        setFetch(!forcefetch);
    }

    return (
        <div className='VideoSetting'>
            <h2>Setting</h2>
            <div className='ClearButton' onClick={() => setState(false)}>
                <AiOutlineClose />
            </div>

            <div style={{display: 'flex', padding: '0px 0px 30px 30px'}}>
                <div style={{width: '50%'}}>
                    <h4>Exposure</h4>
                    <ButtonGroup color="primary" className={classes.buttongroup}>
                        <Button className={classes.button} onClick={() => onClick('exposure',false)}>-</Button>
                        <Button className={classes.button} onClick={() => onClick('exposure',true)}>+</Button>
                    </ButtonGroup>
                </div>
                <div style={{width: '50%'}}>
                    <h4>Gain</h4>
                    <ButtonGroup color="primary" className={classes.buttongroup}>
                        <Button className={classes.button} onClick={() => onClick('gain',false)}>-</Button>
                        <Button className={classes.button} onClick={() => onClick('gain',true)}>+</Button>
                    </ButtonGroup>
                </div>
            </div>

            <div style={{display: 'flex'}}>
                <Select
                    value={color}
                    onChange={onChange}
                    className={classes.select}
                    // style={{backgroundColor: strtorgb(color)}}
                >
                    <MenuItem value='red'>Red</MenuItem>
                    <MenuItem value='yellow'>Yellow</MenuItem>
                    <MenuItem value='pink'>Pink</MenuItem>
                    <MenuItem value='blue'>Blue</MenuItem>
                    <MenuItem value='green'>Green</MenuItem>
                </Select> 

                <Tooltip title='Determine the HSV range for each color to achieve better bounding boxes'>
                    <div style={{padding: '15px 20px'}}>
                        <IconContext.Provider value={{ color: '#303030'}}>
                            <AiOutlineInfoCircle />         
                        </IconContext.Provider>           
                    </div>
                </Tooltip>

                <button onClick={() => onReset(color)} style={{
                    position: 'absolute',
                    right: '10px',
                    marginTop: '12px',
                }}>
                    Reset
                </button>
                
            </div>

            <VideoPage_Sliders color={color} forcefetch={forcefetch} />
        </div>
    )
}

export default VideoPage_Setting

const strtorgb = (str) => {
    switch(str){
        case 'red':
            return 'rgb(233,119,134)';
        case 'yellow':
            return 'rgb(255,245,137)'
        case 'pink':
            return 'rgb(255,192,203)'
        case 'blue':
            return 'rgb(119,191,233)'
        case 'green':
            return 'rgb(119,233,161)'
        default:
            return ''
    }
}