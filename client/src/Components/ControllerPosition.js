function ControllerPosition({position, onClick, onRelease}) {

    return (
        <div>
            <button 
                className='ControllerPosition'
                style={{ backgroundColor: position.state ? 'rgb(255,235,205)' : 'rgb(0,255,255)' }}
                onMouseDown={() => onClick(position.id)}
                onMouseUp={() => onRelease(position.id)}
            >
                <h3>{position.id}</h3>
            </button>
        </div>
    )
}

export default ControllerPosition
