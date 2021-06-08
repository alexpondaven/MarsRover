import { useState, useEffect, Component } from 'react'

function VideoPage() {
    // const [src, setSrc] = useState('http://localhost:5000/bitmap.bmp?' + new Date().getTime());
    const [src, setSrc] = useState('data:image/png;base64,')

    const update = (data) => {
        setSrc('data:image/png;base64,' + data) 
        // setSrc('http://localhost:5000/bitmap.bmp?' + new Date().getTime())
    }

    useEffect(() => {
        getData();
        setInterval(update,5000);
    })

    const getData = async() => {
        fetch('http://localhost:5000/test')
          .then(response => response.json())
          .then(response => update(response.bmp))
    }

    return (
        <div>
            <img src={src} sytle={{width: '80vw'}}/>
        </div>
    )
}

export default VideoPage
