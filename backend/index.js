const express = require('express');
const sql = require('mssql');
const app = express();
const port = process.env.PORT || 3000;

const config = {
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  server: process.env.DB_SERVER,
  database: process.env.DB_DATABASE,
  options: {
    encrypt: true,
    connectTimeout: 30000,
  },
};

app.use(express.json());

app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  console.log('Petición de inicio de sesión recibida:', { email, password });

  try {
    await sql.connect(config);
    const result = await sql.query`SELECT * FROM Trabajadores WHERE email = @email AND password = @password`, {
      email: email,
      password: password
    };

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
