
const sql = require('mssql');

const config = {
  user: 'adminbd',
  password: 'Nintendo7',
  server: 'bbdmodernaserver.database.windows.net',
  database: 'bbd-moderna',
  options: {
    encrypt: true, // Use this if you're on Windows Azure
    connectTimeout: 30000,
  },
};

async function testConnection() {
  try {
    await sql.connect(config);
    console.log('Connection successful!');

    const result = await sql.query('SELECT * FROM Trabajadores');
    console.log('Query result:', result.recordset);
  } catch (err) {
    console.error('Connection failed:', err);
  }
}

testConnection();