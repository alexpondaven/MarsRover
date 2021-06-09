import { useState } from 'react'
import AppBar from '@material-ui/core/AppBar';
import Tabs from '@material-ui/core/Tabs';
import Tab from '@material-ui/core/Tab';
import Typography from '@material-ui/core/Typography';
import Box from '@material-ui/core/Box';
import Tooltip from "@material-ui/core/Tooltip";
import * as Arrow from 'react-icons/im'

import Controller from '../Components/Controller.js'
import ControllerPosition from '../Components/ControllerPosition.js'

function TabPanel(props) {
    const { children, value, index, ...other } = props;
  
    return (
      <div
        role="tabpanel"
        hidden={value !== index}
        id={`simple-tabpanel-${index}`}
        aria-labelledby={`simple-tab-${index}`}
        {...other}
      >
        {value === index && (
          <Box p={3}>
            <Typography>{children}</Typography>
          </Box>
        )}
      </div>
    );
  }

function ControlPage() {
    // left, right, forward, backward
    const [position, setPosition] = useState([
        {
        id: 0,
        name: '',
        state: false,
        },
        {
        id: 1,
        name: 'forward',
        icon: <Arrow.ImArrowUp />,
        state: false,
        },
        {
        id: 2,
        name: '',
        state: false,
        },
        {
        id: 3,
        name: 'left',
        icon: <Arrow.ImArrowLeft />,
        state: false,
        },
        {
        id: 4,
        name: 'stop',
        icon: <Arrow.ImStop2 />,
        state: false,
        },
        {
        id: 5,
        name: 'right',
        icon: <Arrow.ImArrowRight />,
        state: false,
        },
        {
        id: 6,
        name: '',
        state: false,
        },
        {
        id: 7,
        name: 'backward',
        icon: <Arrow.ImArrowDown />,
        state: false,
        },
        {
        id: 8,
        name: '',
        state: false,
        }
    ])

    var bodydir;
    const postDataDir = async(id,bool) => {
        if (explore) setExplore(false);
        if (id === -1) return; 
        bodydir = {
            type: 'direction',
            id: id,
            state: bool
        }
        fetch('http://localhost:5000/position', {
          method: 'POST',
          headers: {
            'Content-type': 'application/json',
          },
          body: JSON.stringify(bodydir),
        }).then(response => console.log(response.json()))
      }
    
    const [curr_dir,setDir] = useState(-1);

    const onClick = async(id) => {
        console.log("clicked id: " + id);
        console.log("current dir: " + curr_dir)
        setPosition(
          position.map((position) =>
            position.id === id ? { ...position, state: true } : position
          )
        )
    
        if (id === 4 && curr_dir !== -1 ){
          let tmp = curr_dir;
          let result = await postDataDir(int_to_int(tmp), false);
          setPosition(
            position.map((position) =>
              position.id === tmp ? { ...position, state: false } : position
            )
          )
          setDir(-1);
        } else if ( id === curr_dir && id !== 4 ) {
          let result = await postDataDir(int_to_int(id), false);
          setPosition(
            position.map((position) =>
              position.id === id ? { ...position, state: false } : position
            )
          )
          setDir(-1);
        } else if ( id !== 4 ) {
          let result = await postDataDir(int_to_int(id),true);
          setDir(id);
        }
    }

    const onRelease = (id) => {
      if (id !== 4) return;
      setPosition(
        position.map((position) =>
          position.id === id ? { ...position, state: false } : position
        )
      )
    }

    // 3x3 grid to array
    const int_to_int = (id) => {
        switch(id) {
        case 1:
            return 2;
        case 3:
            return 0;
        case 5:
            return 1;
        case 7:
            return 3;
        default:
            return -1;
        }
    }

    const [explore,setExplore] = useState(false);

    var bodyexplore;
    const onClickExplore = async(explore) =>{
      bodyexplore = {
        type: 'explore',
        state: !explore
      }
      fetch('http://localhost:5000/position', {
        method: 'POST',
        headers: {
          'Content-type': 'application/json',
        },
        body: JSON.stringify(bodyexplore),
      })
      setExplore(!explore);
    }

    const [value, setValue] = useState(0);

    const handleChange = (event, newValue) => {
        setValue(newValue);
    };

    function a11yProps(index) {
        return {
          id: `simple-tab-${index}`,
          'aria-controls': `simple-tabpanel-${index}`,
        };
      }

    return (
        <div>
            <AppBar position="static" style={{fontFamily: 'Roboto'}}>
                <Tabs 
                    value={value} 
                    onChange={handleChange} 
                    centered
                >
                    <Tooltip title="Control the rover like a RC car by giving it direction command!">
                        <Tab label="Direction" {...a11yProps(0)} />
                    </Tooltip>
                    <Tooltip title="Give the rover a target coordinate, then sit down and wait for it to arrive!">
                        <Tab label="Position" {...a11yProps(1)} />
                    </Tooltip>
                    <Tooltip title="Let the rover chooses where it want to go.">
                        <Tab label="Exploration" {...a11yProps(2)} />
                    </Tooltip>
                </Tabs>
            </AppBar>
            <TabPanel value={value} index={0}>
                <Controller positions={position} onClick={onClick} onRelease={onRelease} />
            </TabPanel>
            <TabPanel value={value} index={1}>
                <ControllerPosition  
                  explore={explore} setExplore={setExplore}
                />
            </TabPanel>
            <TabPanel value={value} index={2}>
              <div style={{width:'80vw', display: 'flex', alignItems: 'center'}}>
                <button 
                  className='ExploreButton' 
                  onClick={() => onClickExplore(explore)} 
                  style={{backgroundColor: explore ? 'rgb(221, 96, 96)' : 'rgb(70,225,70)', 
                          fontFamily: 'Press Start 2P' , fontSize: '300%'}}
                >
                  {explore ? 'Stop' : 'Explore!'}
                </button>
              </div>
            </TabPanel>
        </div>
    )
}

export default ControlPage
