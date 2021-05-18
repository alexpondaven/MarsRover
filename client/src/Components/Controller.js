import ControllerPosition from './ControllerPosition.js'

function Controller({positions,onClick,onRelease}) {
    return (
        <footer className='Controller'>
            {positions.map((position, index) => (
                <ControllerPosition key={index} position={position} onClick={onClick} onRelease={onRelease}/>
            ))}
        </footer>
    )
}

export default Controller
