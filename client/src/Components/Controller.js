import ControllerPosition from './ControllerPosition.js'
import { GridList, GridListTile } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles'

function Controller({positions,onClick,onRelease}) {
    const useStyles = makeStyles((theme) => ({
        root: {
          display: 'flex',
          flexWrap: 'wrap',
          justifyContent: 'space-around',
          overflow: 'hidden',
          backgroundColor: theme.palette.background.paper,
        },
        gridList: {
          width: '100%',
          height: '100%',
        },
      }));
    const classes = useStyles()
    return (
        <div className='Controller'>
            <GridList cols={3} cellHeight={'auto'} spacing={0} className={classes.gridList}>
                {positions.map((position, index) => (
                    <GridListTile key={index}>
                        <ControllerPosition key={index} position={position} onClick={onClick} onRelease={onRelease}/>
                    </GridListTile>
                ))}
            </GridList>
        </div>
    )
}

export default Controller
