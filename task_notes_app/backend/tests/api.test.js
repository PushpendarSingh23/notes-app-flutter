const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/database');

describe('Notes API Endpoints', () => {
  let authToken = '';

  beforeAll(async () => {
    // In a full test environment this would register/login a test user
    // against a dedicated test database and capture a real JWT.
    authToken = 'mocked_valid_jwt_token';
  });

  afterAll(async () => {
    await pool.end();
  });

  it('should reject unauthenticated requests to GET /api/v1/notes', async () => {
    const res = await request(app).get('/api/v1/notes');
    expect(res.statusCode).toEqual(401);
  });

  it('should return 404 for unknown routes', async () => {
    const res = await request(app).get('/api/v1/does-not-exist');
    expect(res.statusCode).toEqual(404);
  });
});
