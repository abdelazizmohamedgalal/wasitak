'use strict';
const crypto = require('node:crypto');
const secret = process.env.JWT_SECRET || crypto.randomBytes(48).toString('hex');
function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  return salt + ':' + crypto.scryptSync(String(password), salt, 64).toString('hex');
}
function verifyPassword(password, value) {
  try {
    const [salt, hash] = String(value).split(':');
    if (!salt || !/^[a-f0-9]{128}$/i.test(hash)) return false;
    const actual = crypto.scryptSync(String(password), salt, 64);
    const expected = Buffer.from(hash, 'hex');
    return actual.length === expected.length && crypto.timingSafeEqual(actual, expected);
  } catch { return false; }
}
function sign(payload) {
  const header = Buffer.from(JSON.stringify({alg:'HS256',typ:'JWT'})).toString('base64url');
  const body = Buffer.from(JSON.stringify({...payload,exp:Math.floor(Date.now()/1000)+43200})).toString('base64url');
  return header+'.'+body+'.'+crypto.createHmac('sha256',secret).update(header+'.'+body).digest('base64url');
}
function verify(token) {
  try {
    const [header,body,sig] = String(token).split('.');
    if (!header || !body || !sig) return null;
    const expected = crypto.createHmac('sha256',secret).update(header+'.'+body).digest();
    const actual = Buffer.from(sig,'base64url');
    if (expected.length !== actual.length || !crypto.timingSafeEqual(expected,actual)) return null;
    const payload = JSON.parse(Buffer.from(body,'base64url'));
    return payload.exp > Date.now()/1000 ? payload : null;
  } catch { return null; }
}
module.exports = {hashPassword,verifyPassword,sign,verify};
