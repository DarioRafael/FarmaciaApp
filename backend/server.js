require('dotenv').config();
const sql = require('mssql');

const dbConfig = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_SERVER,
  database: process.env.DB_DATABASE,
  options: {
    encrypt: true, // Requerido por Azure SQL
    trustServerCertificate: false, // Cambia esto a true si tienes problemas de certificado
  },
};

async function testDbConnection() {
  try {
    const pool = await sql.connect(dbConfig);
    console.log('Conexión a la base de datos exitosa');

    // Aquí puedes agregar la lógica para interactuar con la base de datos, por ejemplo:
    const result = await pool.request()
      .query('SELECT TOP 1 * FROM Trabajadores'); // Ejemplo de consulta

    console.log('Resultado de la consulta:', result.recordset);

    await pool.close();
  } catch (err) {
    console.error('Error al conectar a la base de datos:', err.message);
  }
}

testDbConnection();
