const fs = require('fs')
const csv = require('csv-parser');

var data = [];

fs.createReadStream('./data/SoC_t.csv')
  .pipe(csv())
  .on('data', (row) => {
      if (Number(row.time) == NaN) return;
      if (Number(row.SoC) == NaN) return
      var tmp = {
          x : new Date((Number(row.time) + 1622696882) * 1000),
          y : Number(row.SoC)
      }
    data.push(tmp);
  })
  .on('end', () => {
    // console.log(data);
    // console.log('CSV file successfully processed');
  });

module.exports = data;