import { Link } from 'react-router-dom'

function Header() {
    return (
        <nav className="Navbar">
            <h1> Mars Rover Dashboard</h1>
            <Link to="/" className="links" style={{ textDecoration: 'none'}}>Home</Link>
        </nav>
    )
}

export default Header
