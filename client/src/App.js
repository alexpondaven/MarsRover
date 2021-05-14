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

  useEffect(() => {
    getAxios();
    setInterval(getAxios, 1000)
    // console.log("hi")
  },[]);

  function update(data) {
    setBattery([data.battery]);
    setSpeed([data.speed])
  }

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
