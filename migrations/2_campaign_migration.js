const CampaignManagement = artifacts.require("CampaignManagement");

const config = {
  coinAddress: "0x4f730f7a5acebA1CdBf6EB5aAeB8686D8eA37680",
  token: [
    74666667, 48000000, 30222222, 83555555, 92444444, 92444444, 83555555,
    101333333, 92444444, 74666667,
  ],
  time: [
    "2021/06",
    "2021/12",
    "2022/06",
    "2022/12",
    "2023/06",
    "2023/12",
    "2024/06",
    "2024/12",
    "2025/06",
    "2025/12",
  ],
};
module.exports = function (deployer) {
  let mapTime = config.time.map((data) => Math.round(new Date(data) / 1000));
  deployer.deploy(
    CampaignManagement,
    config.coinAddress,
    mapTime,
    config.token
  );
};
