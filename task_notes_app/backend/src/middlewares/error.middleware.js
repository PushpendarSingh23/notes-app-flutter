const errorHandler = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  if (process.env.NODE_ENV === 'development') {
    return res.status(err.statusCode).json({
      status: err.status,
      error: err,
      message: err.message,
      stack: err.stack,
      details: err.details || null
    });
  }

  if (err.isOperational) {
    return res.status(err.statusCode).json({
      status: err.status,
      message: err.message,
      errorCode: err.errorCode || null,
      details: err.details || null
    });
  }

  console.error('CRITICAL ERROR:', err);
  return res.status(500).json({
    status: 'error',
    message: 'An unexpected internal server error occurred.'
  });
};

module.exports = errorHandler;
