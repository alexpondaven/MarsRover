import { useState, useEffect, Component } from 'react'
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

    const postDataDir = async(id,bool) => {
        if (id === -1) return;
        var body = {
            type: 'direction',
            id: id,
            state: bool
        }
        fetch('http://localhost:5000/position', {
          method: 'POST',
          headers: {
            'Content-type': 'application/json',
          },
          body: JSON.stringify(body),
          
        })
      }
    
    const [curr_dir,setDir] = useState(-1);

    const onClick = (id) => {
        console.log("clicked id: " + id);
        console.log("current dir: " + curr_dir)
        setPosition(
          position.map((position) =>
            position.id === id ? { ...position, state: true } : position
          )
        )
    
        if (id === 4 && curr_dir !== -1 ){
          var tmp = curr_dir;
          postDataDir(int_to_int(tmp), false);
          setPosition(
            position.map((position) =>
              position.id === tmp ? { ...position, state: false } : position
            )
          )
          setDir(-1);
        } else if ( id === curr_dir && id !== 4 ) {
            postDataDir(int_to_int(id), false);
          setPosition(
            position.map((position) =>
              position.id === id ? { ...position, state: false } : position
            )
          )
          setDir(-1);
        } else if ( id !== 4 ) {
          setDir(id);
          postDataDir(int_to_int(id),true);
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

    const [positions,setRover] = useState([]);
    const [currentposition, setCurrent] = useState([]);
    const [obstacles,setObstacle] = useState([]);

    useEffect(() => {
        getData();
        setInterval(getData,1000)
    })

    function update(response) {
        setRover(response.position);
        setCurrent(response.current);
        setObstacle(response.obstacles);
    }

    const getData = async() => {
        fetch('http://localhost:5000/drive')
          .then(response => response.json())
          .then(response => update(response))
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
            <AppBar position="static">
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
                </Tabs>
            </AppBar>
            <TabPanel value={value} index={0}>
                <Controller positions={position} onClick={onClick} onRelease={onRelease} />
            </TabPanel>
            <TabPanel value={value} index={1}>
                <ControllerPosition positions={positions} currentposition={currentposition} obstacles={obstacles} />
            </TabPanel>
        </div>
    )
}

export default ControlPage
