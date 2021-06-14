import { useState, useEffect } from 'react'

function WeatherCard() {
    const [x,set] = useState([]);

    const getData = async() => {
        fetch('http://api.openweathermap.org/data/2.5/weather?q=London&appid=c82ce8c030b7a29097a5c92e0586c51f')
          .then(response => response.json())
          .then(response => set([Number(response.main.temp),Number(response.main.humidity),response.weather[0].description]) )
        //   .then(response => console.log(response))
    }

    useEffect(() => {
      getData();
    },[]);
    
    return (
            <div 
                className='Weather' 
                // style={{backgroundImage: }}
            >

                <h2 className='card-title'>WEATHER</h2>
                <h3>in London</h3>

                <div>
                    <h3>Temperature: {Math.round(x[0]-273)} °C</h3>
                    <h3>Humidity: {x[1]}%</h3>
                    <h4>{x[2]}</h4>
                    <p style={{fontSize: '10px'}}>from OpenWeather</p>
                </div>
                

        </div>
    )
}

export default WeatherCard
