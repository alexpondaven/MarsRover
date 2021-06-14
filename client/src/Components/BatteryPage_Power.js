import ReactApexChart from "react-apexcharts"

function Power({data,battery}) {
    const tmp_data = [{
        name: 'Current',
        data: [10,50]
    },{
        name: 'Voltage',
        data: [100,200]
    }]
    const state = {
        series: tmp_data,
        options : {
            chart: {
                height: '80vh',
                type: 'bar',
            },
            xaxis: {
                categories: ['Battery 1', 'Battery 2'],
            }
        }
    }

    return (
        <div className="Card1" style={{textAlign: 'left'}}>
            <h3>{battery.status ? "Input" : "Output"}</h3>
            <ReactApexChart options={state.options} series={state.series} type="bar" height='80%' width='50%'/>
        </div>
    )
}

export default Power
