const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const signToken = (payload) => {
  const jti = uuidv4();
  return {
    token: jwt.sign(
      { ...payload, jti },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    ),
    jti,
  };
};

module.exports = { signToken };
