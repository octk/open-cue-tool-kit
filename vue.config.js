module.exports = {
  chainWebpack: config => {
    config.module
      .rule("node")
      .test(/\.node$/i)
      .use("node-loader")
      .loader("node-loader");
  }
};
