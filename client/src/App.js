import { useState, useEffect, Component } from 'react'
import { BrowserRouter, Route, Switch, Link } from 'react-router-dom'
import { AiFillHome, AiFillCamera } from 'react-icons/ai';
import { BsBatteryFull } from 'react-icons/bs';
import { RiSteeringFill } from 'react-icons/ri';
import { GiConsoleController } from 'react-icons/gi';
import { IconContext } from 'react-icons';

import Header from './Components/Header.js'
import Battery from './Components/Battery.js'
import BatteryPage from './Pages/BatteryPage.js'
import Speed from './Components/Speed.js'
import DrivePage from './Pages/DrivePage.js'
import ControlCard from './Components/ControlCard.js'
import ControlPage from './Pages/ControlPage.js'
import VideoCard from './Components/VideoCard.js'
import VideoPage from './Pages/VideoPage.js'

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
    },{
      name: 'Video',
      link: '/video',
      icon: <AiFillCamera />,
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
              <div className='HomePage'>
                <div>
                  {batteries.map(battery =>
                    <Battery battery={battery} />
                  )}
                  {speeds.map(speed =>
                    <Speed speed={speed} />
                  )}
                  <ControlCard icon={<GiConsoleController />} />
                  <VideoCard icon={<AiFillCamera />} />
                </div>
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
              <ControlPage />
            </Route>

            <Route path="/video">
              <VideoPage />
            </Route>

          </Switch>
        </div> 
      </div>
    </BrowserRouter>
  );
}

export default App;
