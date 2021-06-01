import { Link } from 'react-router-dom'
import { FaBars } from 'react-icons/fa';
import { IconContext } from 'react-icons';

function Header({onClick, showSidebar}) {
    return (
        <div>
        <IconContext.Provider value={{ color: '#000000' }}>
            <nav className="Navbar">
                <Link to='#' className={showSidebar ? 'SidebarClickActive' : 'SidebarClick'}>
                    <FaBars onClick={onClick} />
                </Link>

                <h1 style={{ marginLeft : '2rem' }}> Mars Rover Dashboard</h1>
                <Link to="/" className="links" style={{ textDecoration: 'none'}}>Home</Link>
            </nav>
        </IconContext.Provider>
        </div>
    )
}

export default Header
