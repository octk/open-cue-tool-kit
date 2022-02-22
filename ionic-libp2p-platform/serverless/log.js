exports.handler = async function({ body }) {
  console.log(body);
  return { statusCode: 200 };
};
