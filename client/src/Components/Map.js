import { Scatter } from 'react-chartjs-2';

function Map({positions, current, obstacles}) {
    console.log(positions)
    const origin = [{
        x: 0,
        y: 0,
        time: new Date(),
        type: 'origin'
    }]
    const data = {
        datasets: [{
            type: 'scatter',
            label: 'rover position',
            data: positions,
            backgroundColor: 'rgb(255, 99, 132)',
            showLine: true,
            pointStyle: 'circle'
        },{
            types: 'scatter',
            label: 'current position',
            data: current,
            backgroundColor: 'rgb(255, 99, 132)',
            pointStyle: 'rect',
            radius: 7
        },{
            types: 'scatter',
            label: 'obstacles',
            data: obstacles,
            backgroundColor: 'rgb(255,255,0)',
            pointStyle: 'circle'
        },{
            type: 'scatter',
            label: 'origin',
            data: origin,
            backgroundColor: 'rgb(0,0,0)',
            pointStyle: 'circle'
        }],
      };
    
    const options = {
        scales:{
            xAxes: {
                display:false,
            },
            yAxes: {
                display:false,
            },
        },
        plugins: {
            legend: {
                display: false,
            },
            tooltip: {
                enabled: true,   
                callbacks: {
                    label: function(context) {
                        var raw = context.raw;
                        var label = [];
                        if (raw.type === 'position') {
                            label = ["time: " + raw.time];
                            label.push(["(" + raw.x + "," + raw.y + ")"]) ;
                        } else {
                            label = "(" + raw.x + "," + raw.y + ")";
                        }
                        
                        return label
                    }
                }         
            }
        },
        animation: {
            duration: 0
        },
        maintainAspectRatio: false
        
    };

    return (
        <div className="Card3">
            <h3>Map</h3>
            <div className="Map">
                <Scatter data={data} options={options} height={370} width='100%'/>
            </div>
        </div>
    )
}

export default Map
