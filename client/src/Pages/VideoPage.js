import { useState, useEffect } from 'react'
import { AiOutlineSetting } from 'react-icons/ai';

import VideoPage_Setting from '../Components/VideoPage_Setting.js'
import { IconContext } from 'react-icons';

var interval = 5000;

function VideoPage() {
    // const [src, setSrc] = useState('http://localhost:5000/bitmap.bmp?' + new Date().getTime());
    const [src, setSrc] = useState('data:image/png;base64,')

    var i = 0;

    const update = (data) => {
        if (data === undefined) {
            interval = 5000;
            return;
        }
        interval = 1000;
        setSrc('data:image/png;base64,' + data) 
        // setSrc('http://localhost:5000/bitmap.bmp?' + new Date().getTime())
        console.log("fetched for video " + i);
        i++;
    }

    useEffect(() => {
        getData();
        setInterval(getData,interval);
    },[])

    const getData = async() => {
        fetch('http://localhost:5000/video')
          .then(response => response.json())
          .then(response => update(response.bmp))
    }

    const [setting, setSetting] = useState(false);

    return (
        <div>
            <div style={{width:'80vh'}}>
                <img src={src} width='100%'/> 
            </div>
            {setting ? <VideoPage_Setting setState={setSetting}/> : ''}
            <div className='ClearButton' style={{
                position: 'absolute',
                top: '120px',
                right: '0',
            }}>
                <IconContext.Provider value={{ color: '#808080', size: '30px'}}>
                    {setting ? '' : <AiOutlineSetting onClick={() => setSetting(true)}/> }
                </IconContext.Provider>
            </div>
        
        </div>
    )
}

export default VideoPage
