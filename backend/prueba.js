require('dotenv').config();
const sql = require('mssql');

const config = {
user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_SERVER,
  database: process.env.DB_DATABASE,
  options: {
    encrypt: true,
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