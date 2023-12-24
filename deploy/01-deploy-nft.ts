import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../helper-functions"
import { networkConfig, developmentChains } from "../helper-hardhat-config"

const deployNFT: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  // @ts-ignore
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  log("----------------------------------------------------")
  log("Deploying NFT and waiting for confirmations...")
  const NFT = await deploy("NounsWrapped", {
    from: deployer,
    args: [
      // Owner
      deployer,
      // Mint Fee (0.001 ETH)
      1000000000000000,
    ],
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: networkConfig[network.name]?.blockConfirmations || 1,
  })
  log(`NFT at ${NFT.address}`)
  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    await verify(NFT.address, [
      // Owner
      deployer,
      // Mint Fee (0.001 ETH)
      1000000000000000,
    ])
  }
}

export default deployNFT
deployNFT.tags = ["all", "NFT"]
