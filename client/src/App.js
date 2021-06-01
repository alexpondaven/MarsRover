import { useState, useEffect, Component } from 'react'
import { BrowserRouter, Route, Switch, Link } from 'react-router-dom'
import { AiFillHome } from 'react-icons/ai';
import { BsBatteryFull } from 'react-icons/bs';
import { RiSteeringFill } from 'react-icons/ri';
import { IconContext } from 'react-icons';

import Header from './Components/Header.js'
import Battery from './Components/Battery.js'
import BatteryPage from './Pages/BatteryPage.js'
import Speed from './Components/Speed.js'
import DrivePage from './Pages/DrivePage.js'
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
      id: 'left',
      state: false,
    },
    {
      id: 'right',
      state: false,
    },
    {
      id: 'forward',
      state: false,
    },
    {
      id: 'backward',
      state: false,
    },
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

  const onClick = (id) => {
    setPosition(
        position.map((position) =>
        position.id === id ? { ...position, state: true } : position
      )
    )
    postData(string_to_int(id),true);
  }

  const onRelease = (id) => {
    setPosition(
      position.map((position) =>
        position.id === id ? { ...position, state: false } : position
      )
    )
    postData(string_to_int(id),false);
  }

  const string_to_int = (str) => {
    switch(str) {
      case "left":
        return 0;
      case "right":
        return 1;
      case "forward":
        return 2;
      case "backward":
        return 3;
      default:
        return -1
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
                <Controller positions={position} onClick={onClick} onRelease={onRelease} />
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

            <Route path="/test">
              <TestingPage />
            </Route>

          </Switch>
        </div> 
      </div>
    </BrowserRouter>
  );
}

export default App;
