import { NounsWrapped } from "../../typechain-types"
import { deployments, ethers } from "hardhat"
import { assert } from "chai"

import { parseEther } from "ethers/lib/utils"

describe("NounsWrapped Mint Flow", () => {
  let nounsWrapped: NounsWrapped

  beforeEach(async () => {
    await deployments.fixture(["all"])
    nounsWrapped = await ethers.getContract("NounsWrapped")
  })

  it("Mint NFT", async () => {
    const toAddress = "0x0cfecb5D359E6C59ABd1d2Aa794F52C15055f451"
    const fid = 8754462663
    const stats = {
      mins: 11,
      streak: 110,
      username: "super.skywalker",
    }
    const value = parseEther("0.001")

    const res0 = await nounsWrapped.mint(toAddress, fid, stats, { value })
    const tx0 = await res0.wait(1)
    const tokenId = tx0.events![0].args!.tokenId
    console.log("tokenId", tokenId.toString())

    // Additional assertions and edge cases
    assert.exists(tokenId, "Token ID should exist")
    assert.isAbove(tokenId.toNumber(), 0, "Token ID should be greater than 0")

    // Test minting with different values
    const res1 = await nounsWrapped.mint(toAddress, fid + 1, stats, { value })
    const tx1 = await res1.wait(1)
    const tokenId1 = tx1.events![0].args!.tokenId
    console.log("tokenId1", tokenId1.toString())
    assert.notEqual(tokenId1, tokenId, "Token ID should be different")

    // Test minting with different addresses
    const toAddress2 = "0x1234567890123456789012345678901234567890"
    const res2 = await nounsWrapped.mint(toAddress2, fid, stats, { value })
    const tx2 = await res2.wait(1)
    const tokenId2 = tx2.events![0].args!.tokenId
    console.log("tokenId2", tokenId2.toString())
    assert.notEqual(tokenId2, tokenId, "Token ID should be different")

    // Test minting with different props
    const stats2 = {
      mins: 10,
      streak: 100,
      username: "test.user",
    }
    const res3 = await nounsWrapped.mint(toAddress, fid, stats2, { value })
    const tx3 = await res3.wait(1)
    const tokenId3 = tx3.events![0].args!.tokenId
    console.log("tokenId3", tokenId3.toString())
    assert.notEqual(tokenId3, tokenId, "Token ID should be different")
  })
})
