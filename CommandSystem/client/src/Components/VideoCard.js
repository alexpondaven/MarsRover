import { Link } from 'react-router-dom'
import { IconContext } from 'react-icons';

function VideoCard({icon}) {
    return (
        <Link to="/video" style={{ textDecoration: 'none' , textColor: 'black'}} >
            <div 
                className='HomeBlock' 
            >
                <h2 className='card-title'>VIDEO</h2>
            <IconContext.Provider value={{ color: '#fe019a', size: '90%' }}>
                {icon}
            </IconContext.Provider>
        </div>
       </Link>
    )
}

export default VideoCard
