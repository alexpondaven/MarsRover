import { useState, useEffect, Component } from 'react'
import { BrowserRouter, Route, Switch, Link } from 'react-router-dom'
import { AiFillHome } from 'react-icons/ai';
import { BsBatteryFull } from 'react-icons/bs';
import { RiSteeringFill } from 'react-icons/ri';
import { GiConsoleController } from 'react-icons/gi';
import { IconContext } from 'react-icons';
import * as Arrow from 'react-icons/im'

import Header from './Components/Header.js'
import Battery from './Components/Battery.js'
import BatteryPage from './Pages/BatteryPage.js'
import Speed from './Components/Speed.js'
import DrivePage from './Pages/DrivePage.js'
import ControlCard from './Components/ControlCard.js'
import Controller from './Components/Controller.js'

import TestingPage from './Pages/TestingPage.js'

function App() {
  const [showSidebar, setSidebar] = useState(false);
  const Sidebar = () => setSidebar(!showSidebar);
  const SidebarData = [{
    name: 'Home',
    link: '/',
    icon: <AiFillHome />,
  },{
      name: 'Battery',
      link: '/battery',
      icon: <BsBatteryFull />,
  },{
      name: 'Drive',
      link: '/speed',
      icon: <RiSteeringFill />,
  },{
      name: 'Controller',
      link: '/controller',
      icon: <GiConsoleController />,
  }]

  const [batteries, setBattery] = useState([
    {
      status: true,
      remain : '34%',
      health: '30%',
    }
  ]) 

  const [speeds, setSpeed] = useState([
    {
      speed : 43,
      angle : 0
    }
  ])

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

  // update value of battery and speed
  function update(data) {
    setBattery([data.battery]);
    setSpeed([data.speed])
  }

  // fetch from server and call function update to update data
  const getData = async() => {
    fetch('http://localhost:5000/data')
      .then(response => response.json())
      .then(response => update(response))
  }

  // this would be run when function called
  useEffect(() => {
    getData();
    // getData called every 1s
    setInterval(getData, 1000)
  });

  const postData = async(id,bool) => {
    if (id === -1) return;
    var body = {
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
      postData(int_to_int(tmp), false);
      setPosition(
        position.map((position) =>
          position.id === tmp ? { ...position, state: false } : position
        )
      )
      setDir(-1);
    } else if ( id === curr_dir && id !== 4 ) {
      postData(int_to_int(id), false);
      setPosition(
        position.map((position) =>
          position.id === id ? { ...position, state: false } : position
        )
      )
      setDir(-1);
    } else if ( id !== 4 ) {
      setDir(id);
      postData(int_to_int(id),true);
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

  return (
    <BrowserRouter>
      <div className="App" style={{display: 'grid'}}>
        <Header onClick={Sidebar} showSidebar={showSidebar}/>      

        <div style={{display: 'flex'}}>

          <nav className={showSidebar ? 'SidebarActive' : 'Sidebar'}>
            <ul className='SidebarItems'>
              {SidebarData.map((item, index) => {
                return (
                  <li key={index} className='SidebarItem'>
                    <Link to={item.link}>
                      {item.icon}
                      <span>{showSidebar ? item.name : ''}</span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          </nav>

          <Switch>
            <Route exact path="/">
              <div className='SubPage'>
                {batteries.map(battery =>
                  <Battery battery={battery} />
                )}
                {speeds.map(speed =>
                  <Speed speed={speed} />
                )}
                <ControlCard icon={<GiConsoleController />} />
              </div>
            </Route>

            <Route path="/battery">
              {batteries.map(battery =>
                <BatteryPage battery={battery} />
              )}
            </Route>

            <Route path="/speed">
              {speeds.map(speed =>
                  <DrivePage speed={speed} />
              )}
            </Route>

            <Route path="/controller">
              <Controller positions={position} onClick={onClick} onRelease={onRelease} />
            </Route>

            {/* <Route path="/test">
              <TestingPage />
            </Route> */}

          </Switch>
        </div> 
      </div>
    </BrowserRouter>
  );
}

export default App;
