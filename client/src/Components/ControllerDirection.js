import { IconContext } from 'react-icons';

function ControllerDirection({position, onClick, onRelease}) {
    var state = false;
    if (position.name !== '') state = true;

    return (
        <div>
            <button 
                className={state ? 'ControllerPosition' : 'ControllerPositionDisabled'}
                style={{ backgroundColor: state ? position.state ? 'rgb(255,235,205)' : 'rgb(0,255,255)' : 'rgb(255,255,255)' }}
                onMouseDown={() => onClick(position.id)}
                onMouseUp={() => onRelease(position.id)}
            >
                <IconContext.Provider value={{ color: '#535353', size: '50%' }}>
                    {state ? position.icon : ''}
                </IconContext.Provider>
                
            </button>
        </div>
    )
}

export default ControllerDirection
