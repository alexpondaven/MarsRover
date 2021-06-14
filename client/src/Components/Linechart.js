import ReactApexChart from "react-apexcharts"

function Linechart({data1,name1, data2,name2,name,limit}) {
    const state = {
        series: [{
            name: name1,
            data: data1
        },{
          name: name2,
          data: data2,
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
          // yaxis: {
          //   max: limit ? 100: function(max) { return max },
          //   min: 0
          // }
        },
      
      
      };


    return (
        <div>
            <h3>{name}</h3>
            <ReactApexChart options={state.options} series={state.series} type="area" height={350} width='100%'/>
        </div>
    )
}

export default Linechart