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
    encrypt: true, // Use this if you're on Windows Azure
    connectTimeout: 30000,
  },
};

app.use(express.json());

app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  console.log('Petición de inicio de sesión recibida:', { email, password });

  try {
    await sql.connect(config);
    const result = await sql.query`SELECT * FROM Trabajadores WHERE email = ${email} AND password = ${password}`;

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