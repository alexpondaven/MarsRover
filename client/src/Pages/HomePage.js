import { useState, useEffect } from 'react'
import { AiFillCamera } from 'react-icons/ai';
import { GiConsoleController } from 'react-icons/gi';
import { BsFillPeopleFill } from 'react-icons/bs';

import Battery from '../Components/Battery.js'
import Speed from '../Components/Speed.js'
import ControlCard from '../Components/ControlCard.js'
import VideoCard from '../Components/VideoCard.js'
import AboutUsCard from '../Components/AboutUsCard.js'

function HomePage() {
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
          .then(response => update(response) )
          .then(console.log("fetched"))
      }
    
      // this would be run when function called
      useEffect(async() => {
        const result = await getData();
        // getData called every 10s
        setTimeout(getData, 10000)
      },[]);

    return (
        <div className='HomePage'>
            <div>
              {batteries.map((battery,index) =>
                <Battery key={index} battery={battery} />
              )}
              {speeds.map((speed,index) =>
                <Speed key={index} speed={speed} />
              )}
              <ControlCard icon={<GiConsoleController />} />
              <VideoCard icon={<AiFillCamera />} />
              <AboutUsCard icon={<BsFillPeopleFill />}/>
            </div>
        </div>
    )
}

export default HomePage
