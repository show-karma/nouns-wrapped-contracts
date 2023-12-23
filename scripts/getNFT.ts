import { ethers } from "hardhat"
import { NounsWrapped } from "../typechain-types"

export async function main(args: any[]) {
  const nounsWrapped: NounsWrapped = await ethers.getContract("NounsWrapped")

  const data = await nounsWrapped.tokenURI(args[0])
  let decoded = Buffer.from(data.replace("data:application/json;base64,", ""), "base64").toString()
  let decodedJSON = JSON.parse(decoded)
  console.log(decodedJSON)
}

main([
  54255, // uid
])
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
