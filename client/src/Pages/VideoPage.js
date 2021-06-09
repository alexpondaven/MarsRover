import { useState, useEffect } from 'react'
var interval = 5000;

function VideoPage() {
    // const [src, setSrc] = useState('http://localhost:5000/bitmap.bmp?' + new Date().getTime());
    const [src, setSrc] = useState('data:image/png;base64,')

    const update = (data) => {
        if (data === undefined) {
            interval = 5000;
            return;
        }
        interval = 1000;
        setSrc('data:image/png;base64,' + data) 
        // setSrc('http://localhost:5000/bitmap.bmp?' + new Date().getTime())
    }

    useEffect(() => {
        getData();
        setInterval(update,interval);
    },[])

    const getData = async() => {
        fetch('http://localhost:5000/video')
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
