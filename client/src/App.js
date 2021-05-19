import { useState, useEffect, Component } from 'react'

import Header from './Components/Header.js'
import Battery from './Components/Battery.js'
import Speed from './Components/Speed.js'
import Controller from './Components/Controller.js'

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

  // this would be run when function called
  useEffect(() => {
    getData();
    // getData called every 1s
    setInterval(getData, 1000)
  },[]);

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
      
    }).then()
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
    <div className="App">
      <Header />
        {batteries.map(battery =>
          <Battery battery={battery} />
        )}
        {speeds.map(speed =>
          <Speed speed={speed} />
        )}
      <Controller positions={position} onClick={onClick} onRelease={onRelease} />
      
    </div>
  );
}

export default App;
