import { Link } from 'react-router-dom'
import { IconContext } from 'react-icons';

function AboutUsCard({icon}) {
    return (
        <Link to="/aboutus" style={{ textDecoration: 'none' , textColor: 'black'}} >
            <div 
                className='HomeBlock' 
            >
                <h2 className='card-title'>ABOUT US</h2>
                <IconContext.Provider value={{ color: '#303030', size: '70%' }}>
                    {icon}
                </IconContext.Provider>
            </div>
       </Link>
    )
}

export default AboutUsCard
