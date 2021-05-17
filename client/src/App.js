import { useState, useEffect, Component } from 'react'

import Header from './Components/Header.js'
import Battery from './Components/Battery.js'
import Speed from './Components/Speed.js'

function App() {
  const [batteries, setBattery] = useState([
    {
      status: true,
      remain : '34%',
    }
  ]) 

  const [speeds, setSpeed] = useState([
    {
      speed : 43
    }
  ])

  // this would be run when function called
  useEffect(() => {
    getAxios();
    // getAxios called every 1s
    setInterval(getAxios, 1000)
  },[]);

  // update value of battery and speed
  function update(data) {
    setBattery([data.battery]);
    setSpeed([data.speed])
  }

  // fetch from server and call function update to update data
  const getAxios = async() => {
    fetch('http://localhost:5000/hi')
      .then(response => response.json())
      .then(response => update(response))
  }

  return (
    <div className="App">
      <Header />
        {batteries.map(battery =>
          <Battery battery={battery} />
        )}
        {speeds.map(speed =>
          <Speed speed={speed} />
        )}
      
    </div>
  );
}

export default App;
