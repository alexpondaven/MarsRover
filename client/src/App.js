import { useState } from 'react'
import { BrowserRouter, Route, Switch, Link } from 'react-router-dom'
import { AiFillHome, AiFillCamera } from 'react-icons/ai';
import { BsBatteryFull } from 'react-icons/bs';
import { RiSteeringFill } from 'react-icons/ri';
import { GiConsoleController } from 'react-icons/gi';
import { IconContext } from 'react-icons';

import Header from './Components/Header.js'
import HomePage from './Pages/HomePage.js'
import BatteryPage from './Pages/BatteryPage.js'
import DrivePage from './Pages/DrivePage.js'
import ControlPage from './Pages/ControlPage.js'
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
            <Route exact path="/" render={() => {
              console.log("home");
              return <HomePage />;
            }} />

            <Route path="/battery" render={() => {
              console.log("battery");
              return <BatteryPage />;
            }} />

            <Route path="/speed">
              <DrivePage />
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
