import { GridList, GridListTile } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles'

import ControllerDirection from './ControllerDirection.js'

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
        <div style={{width:'80vw', display: 'flex', alignItems: 'center'}}>
            <div className='Controller'>
                <GridList cols={3} cellHeight={'auto'} spacing={0} className={classes.gridList}>
                    {positions.map((position, index) => (
                        <GridListTile key={index}>
                            <ControllerDirection key={index} position={position} onClick={onClick} onRelease={onRelease}/>
                        </GridListTile>
                    ))}
                </GridList>
            </div>
        </div>
    )
}

export default Controller
