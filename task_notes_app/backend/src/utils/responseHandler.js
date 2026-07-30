const sendResponse = (res, statusCode, message, data = null, meta = null) => {
  const response = {
    status: `${statusCode}`.startsWith('2') ? 'success' : 'fail',
    message,
  };

  if (data !== null) {
    response.data = data;
  }

  if (meta !== null) {
    response.meta = meta;
  }

  return res.status(statusCode).json(response);
};

module.exports = { sendResponse };
