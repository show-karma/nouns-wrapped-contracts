import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../helper-functions"
import { parseEther } from "ethers/lib/utils"
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
      // Mint Fee
      parseEther("0.0001"), // Wei 100000000000000
    ],
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: networkConfig[network.name]?.blockConfirmations || 1,
  })
  log(`NFT at ${NFT.address}`)
  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    // Wait for 5 block confirmations
    log("Waiting for 5 block confirmations before verifying...")
    await hre.ethers.provider.waitForTransaction(NFT.transactionHash || "", 5)

    await verify(NFT.address, network.name, [
      // Owner
      deployer,
      // Mint Fee
      parseEther("0.0001"), // Wei 100000000000000
    ])
  }
}

export default deployNFT
deployNFT.tags = ["all", "NFT"]
