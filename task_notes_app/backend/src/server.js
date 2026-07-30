const http = require('http');
const dotenv = require('dotenv');
const app = require('./app');
const { pool } = require('./config/database');

dotenv.config();

const PORT = process.env.PORT || 5000;
const server = http.createServer(app);

const startServer = async () => {
  try {
    const connection = await pool.getConnection();
    connection.release();
    console.log('MySQL Database Connected Successfully.');

    server.listen(PORT, () => {
      console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to connect to MySQL Database:', error.message);
    process.exit(1);
  }
};

process.on('unhandledRejection', (err) => {
  console.error('UNHANDLED REJECTION! Shutting down...', err);
  server.close(() => process.exit(1));
});

startServer();
