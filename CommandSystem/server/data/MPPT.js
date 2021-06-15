const fs = require('fs')
const csv = require('csv-parser');

var data = [];

fs.createReadStream('./data/mppt_volt.csv')
  .pipe(csv())
  .on('data', (row) => {
      if (Number(row.MPPT) == NaN) return;
      if (Number(row.voltage) == NaN) return
      var tmp = {
          y : Number(row.MPPT),
          x : Number(row.voltage)
      }
    data.push(tmp);
  })
  .on('end', () => {
  });

  module.exports = data;