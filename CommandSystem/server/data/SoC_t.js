const fs = require('fs')
const csv = require('csv-parser');

var data1 = [];
var data2 = [];
var data3 = [];

fs.createReadStream('./data/soc1_time.csv')
  .pipe(csv())
  .on('data', (row) => {
      if (Number(row.time) == NaN) return;
      if (Number(row.SoC) == NaN) return
      var tmp = {
          x : new Date((Number(row.time) + 1622696882) * 1000),
          y : Number(row.SoC)
      }
    data1.push(tmp);
  })
  .on('end', () => {
    // console.log(data);
    // console.log('CSV file successfully processed');
  });

  fs.createReadStream('./data/soc2_time.csv')
  .pipe(csv())
  .on('data', (row) => {
      if (Number(row.time) == NaN) return;
      if (Number(row.SoC) == NaN) return
      var tmp = {
          x : new Date((Number(row.time) + 1622696882) * 1000),
          y : Number(row.SoC)
      }
    data2.push(tmp);
  })
  .on('end', () => {
    // console.log(data);
    // console.log('CSV file successfully processed');
  });

const data = {
  data1: data1,
  data2: data2,
};

module.exports = data;