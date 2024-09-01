const express = require('express');
const sql = require('mssql');
const app = express();
const port = 3000;

const config = {
  user: 'adminbd',
  password: 'Nintendo7',
  server: 'bbdmodernaserver.database.windows.net',
  database: 'bbd-moderna',
  options: {
    encrypt: true, // Usa esto si estás en Azure
    connectTimeout: 30000,
  },
};

app.use(express.json());

app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  console.log('Petición de inicio de sesión recibida:', { email, password });

  try {
    // Conectar a la base de datos
    const pool = await sql.connect(config);

    // Crear una solicitud
    const request = pool.request();

    // Realizar la consulta con los nombres de columnas correctos
    const result = await request
      .input('correo', sql.VarChar, email)  // Usar 'correo' para el email
      .input('contraseña', sql.VarChar, password)  // Usar 'contraseña' para la contraseña
      .query('SELECT * FROM Trabajadores WHERE correo = @correo AND contraseña = @contraseña');

    if (result.recordset.length > 0) {
      res.status(200).send('Login successful');
    } else {
      res.status(401).send('Invalid email or password');
    }
  } catch (err) {
    console.error('Connection failed:', err);
    res.status(500).send('Server error');
  }
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
