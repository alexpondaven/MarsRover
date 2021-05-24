import ReactApexChart from "react-apexcharts"

function Linechart({data,name}) {
    const state = {
        series: [{
            name: "Charge",
            data: data
        }],
        options: {
          chart: {
            height: 350,
            type: 'line',
            zoom: {
                type: 'x',
                enabled: true,
                autoScaleYaxis: true
              },
              toolbar: {
                autoSelected: 'zoom'
              }
          },
          dataLabels: {
            enabled: false
          },
          stroke: {
            curve: 'straight'
          },
          grid: {
            row: {
              colors: ['#f3f3f3', 'transparent'], // takes an array which will be repeated on columns
              opacity: 0.5
            },
          },
          xaxis: {
            type: 'datetime',
          },
          yaxis: {
            max: 100,
            min: 0
          }
        },
      
      
      };


    return (
        <div className="Card3">
            <h3>{name}</h3>
            <ReactApexChart options={state.options} series={state.series} type="area" height={350} />
        </div>
    )
}

export default Linechart