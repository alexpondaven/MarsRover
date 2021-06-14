import ReactApexChart from "react-apexcharts"

function Linechart({type,data1, data2,name}) {
    const state = type ?
     {
        series: [{
            name: "Battery 1",
            data: data1
        },{
          name: "Battery 2",
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
          yaxis: {
            max: 100,
            min: 0
          }
        },
      } 
      :
      {
        series: [{
            name: "Power",
            data: data1
        }],
        options: {
          chart: {
            height: 350,
            type: 'scatter',
            zoom: {
                type: 'x',
                enabled: true,
                autoScaleYaxis: true
              },
              toolbar: {
                autoSelected: 'zoom'
              }
          },
          xaxis: {
            tickAmount: 20,
            title: {
              text: 'Voltage'
            }
          },
          yaxis: {
            title: {
              text: 'Power'
            }
          }
        },

      };


    return (
        <div>
            <h3>{name}</h3>
            <ReactApexChart options={state.options} series={state.series} type={type ? 'area' : 'scatter'} height={350} width='100%'/>
        </div>
    )
}

export default Linechart