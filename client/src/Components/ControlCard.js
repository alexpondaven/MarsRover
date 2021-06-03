import { Link } from 'react-router-dom'
import { IconContext } from 'react-icons';
import { GiConsoleController } from 'react-icons/gi';

function ControlCard({icon}) {
    return (
        <Link to="/controller" style={{ textDecoration: 'none' , textColor: 'black'}} >
        <div 
            className='HomeBlock' 
        >
            <h2 className='card-title'>CONTROLLER</h2>
        <IconContext.Provider value={{ color: '#fe019a', size: '90%' }}>
            {icon}
        </IconContext.Provider>
       </div>
       </Link>
    )
}

export default ControlCard
